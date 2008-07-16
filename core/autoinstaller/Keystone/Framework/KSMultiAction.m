//
//  KSMultiAction.m
//  Keystone
//
//  Created by Greg Miller on 2/14/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import "KSMultiAction.h"
#import "KSActionProcessor.h"


@implementation KSMultiAction

- (id)init {
  if ((self = [super init])) {
    subProcessor_ = [[KSActionProcessor alloc] initWithDelegate:self];
  }
  return self;
}

- (void)dealloc {
  [subProcessor_ setDelegate:nil];
  [subProcessor_ release];
  [super dealloc];
}

- (void)terminateAction {
  [subProcessor_ stopProcessing];
}

- (int)subActionsProcessed {
  return subActionsProcessed_;
}

//
// KSActionProcessor delegate methods.
// These callbacks will come from our |subProcessor_|
//

- (void)processingStarted:(KSActionProcessor *)processor {
  // Count the number of subactions that we're going to process
  subActionsProcessed_ = [[processor actions] count];
}

// When our subProcessor is finished, then we are done ourselves.
- (void)processingDone:(KSActionProcessor *)processor {
  [[self processor] finishedProcessing:self successfully:YES];
}

@end


@implementation KSMultiAction (ProtectedMethods)

- (KSActionProcessor *)subProcessor {
  return subProcessor_;
}

@end
