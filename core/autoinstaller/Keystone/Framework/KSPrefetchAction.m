//
//  KSPrefetchAction.m
//  Keystone
//
//  Created by Greg Miller on 2/14/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import "KSPrefetchAction.h"
#import "KSKeystone.h"
#import "KSActionPipe.h"
#import "KSDownloadAction.h"
#import "KSActionProcessor.h"
#import "KSUpdateInfo.h"


@implementation KSPrefetchAction

+ (id)actionWithKeystone:(KSKeystone *)keystone {
  return [[[self alloc] initWithKeystone:keystone] autorelease];
}

- (id)init {
  return [self initWithKeystone:nil];
}

- (id)initWithKeystone:(KSKeystone *)keystone {
  if ((self = [super init])) {
    keystone_ = [keystone retain];
    if (keystone_ == nil) {
      [self release];
      return nil;
    }
  }
  return self;
}

- (void)dealloc {
  [keystone_ release];
  [super dealloc];
}

- (void)performAction {  
  NSArray *availableUpdates = [[self inPipe] contents];
  // Our output must always be the same as our input, so we'll set that up now
  [[self outPipe] setContents:availableUpdates];
  
  if (availableUpdates == nil) {
    GMLoggerInfo(@"no updates available.");
    [[self processor] finishedProcessing:self successfully:YES];
    return;
  }

  _GTMDevAssert(keystone_ != nil, @"keystone_ must not be nil");
  
  // Send the available updates to the delegate to figure out which ones should
  // be prefetched. The delegate will return an array of product dictionaries
  // that we should prefetch.
  //
  // Security note:
  // The delegate is untrusted so we can't trust the product dictionaries that
  // we get back. So, we use the returned product dictionaries to filter our
  // original list of |availableUpdates| to the ones the delegate requested.
  NSArray *updatesToPrefetch = [keystone_ action:self
                          shouldPrefetchProducts:availableUpdates];
  
  // Filter our list of available updates to only those that the delegate told
  // us to prefetch.
  NSArray *prefetches =
    [availableUpdates filteredArrayUsingPredicate:
     [NSPredicate predicateWithFormat:
      @"SELF IN %@", updatesToPrefetch]];
  
  // Use -description because it prints nicer than the way CF would format it
  GMLoggerInfo(@"prefetches=%@", [prefetches description]);
  
  // Convert each dictionary in |prefetches| into a KSDownloadAction and
  // enqueue it on our subProcessor
  NSEnumerator *prefetchEnumerator = [prefetches objectEnumerator];
  KSUpdateInfo *info = nil;
  while ((info = [prefetchEnumerator nextObject])) {
    NSString *dmgName =
    [[info productID] stringByAppendingPathExtension:@"dmg"];
    KSAction *action =
    [KSDownloadAction actionWithURL:[info codebaseURL]
                               size:[[info codeSize] intValue]
                               hash:[info codeHash]
                               name:dmgName];
    [[self subProcessor] enqueueAction:action];
  }

  if ([[[self subProcessor] actions] count] == 0) {
    GMLoggerInfo(@"No prefetch downloads created.");
    [[self processor] finishedProcessing:self successfully:YES];
    return;
  }
  
  [[self subProcessor] startProcessing];
}

@end
