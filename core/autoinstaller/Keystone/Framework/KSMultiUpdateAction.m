//
//  KSMultiUpdateAction.m
//  Keystone
//
//  Created by Greg Miller on 2/26/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import "KSMultiUpdateAction.h"
#import "KSKeystone.h"
#import "KSActionProcessor.h"
#import "KSActionPipe.h"
#import "KSUpdateInfo.h"
#import "KSUpdateAction.h"
#import "KSFrameworkStats.h"


@implementation KSMultiUpdateAction

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

- (KSKeystone *)keystone {
  return keystone_;
}

- (void)performAction {  
  NSArray *availableUpdates = [[self inPipe] contents];
  if (availableUpdates == nil) {
    GMLoggerInfo(@"no updates available.");
    [[self processor] finishedProcessing:self successfully:YES];
    return;
  }
  
  _GTMDevAssert(keystone_ != nil, @"keystone_ must not be nil");
  
  // Call through to our "pure virtual" method that the concrete subclass 
  // should have overridden to figure out which of the available prodcuts we
  // should actually update.
  NSArray *productsToUpdate =
    [self productsToUpdateFromAvailable:availableUpdates];
  
  // Filter our list of available updates to only those that we were told to
  // update. We don't simply use |productsToUpdate| because we may not be able
  // to trust the contents of that dictionary. Instead, we use productsToUpdate
  // to filter our dictionary, which we know we can trust.
  NSArray *filteredUpdates =
    [availableUpdates filteredArrayUsingPredicate:
     [NSPredicate predicateWithFormat:
      @"SELF IN %@", productsToUpdate]];
  
  NSArray *remainingUpdates =
    [availableUpdates filteredArrayUsingPredicate:
     [NSPredicate predicateWithFormat:
      @"NOT SELF IN %@", productsToUpdate]];
  
  // Set our outPipe to contain all of the updates that we did not do.
  [[self outPipe] setContents:remainingUpdates];
  
  // Make sure the union of our filteredUpdates and the remainingUpdates is 
  // equal to our availableUpdates. We use NSSets because we don't care about 
  // the order.
  _GTMDevAssert([[NSSet setWithArray:
             [filteredUpdates arrayByAddingObjectsFromArray:remainingUpdates]] 
            isEqualToSet:[NSSet setWithArray:availableUpdates]],
           @"filteredUpdates + remainingUpdates should equal availableUpdates");
  
  // Use -description because it prints nicer than the way CF would format it
  GMLoggerInfo(@"filteredUpdates=%@", [filteredUpdates description]);
  
  // Convert each dictionary in |filteredUpdates| into a KSUpdateAction and
  // enqueue it on our subProcessor_
  NSEnumerator *filteredUpdateEnumerator = [filteredUpdates objectEnumerator];
  KSUpdateInfo *info = nil;
  while ((info = [filteredUpdateEnumerator nextObject])) {
    id<KSCommandRunner> runner = [keystone_ commandRunnerForAction:self];
    KSAction *action =
      [KSUpdateAction actionWithUpdateInfo:info
                                    runner:runner
                             userInitiated:NO];
    [[self subProcessor] enqueueAction:action];
  }
  
  if ([[[self subProcessor] actions] count] == 0) {
    GMLoggerInfo(@"No update actions created for filteredUpdates.");
    [[self processor] finishedProcessing:self successfully:YES];
    return;
  }
  
  [[self subProcessor] startProcessing];
}

- (void)processor:(KSActionProcessor *)processor
   startingAction:(KSAction *)action {
  KSUpdateAction *ua = (KSUpdateAction *)action;
  [[self keystone] action:self
                 starting:[ua updateInfo]];
}

- (void)processor:(KSActionProcessor *)processor
   finishedAction:(KSAction *)action
     successfully:(BOOL)wasOK {
  KSUpdateAction *ua = (KSUpdateAction *)action;
  
  // Record the return code from the update action
  NSNumber *rc = [ua returnCode];
  rc = (rc ? rc : [NSNumber numberWithInt:-1]);
  KSUpdateInfo *ui = [ua updateInfo];
  NSString *statKey = KSMakeProductStatKey([ui productID], kStatInstallRC);
  [[KSFrameworkStats sharedStats] setNumber:rc forStat:statKey];
  
  GMLoggerInfo(@"Got return code %@ after updating %@", rc, ui);
  
  [[self keystone] action:self
                 finished:[ua updateInfo]
               wasSuccess:wasOK
              wantsReboot:[ua wantsReboot]];
}

@end
