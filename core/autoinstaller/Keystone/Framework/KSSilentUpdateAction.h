//
//  KSSilentUpdateAction.h
//  Keystone
//
//  Created by Greg Miller on 2/19/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KSMultiUpdateAction.h"

@class KSKeystone, KSActionProcessor;

// KSSilentUpdateAction
//
// This concrete KSMultiAction subclass that takes input from its inPipe, which
// must be an array of product dictionaries (see KSUpdateInfo.h for more details
// on the format), and messages the keystone_'s delegate to find out which of
// the products in the array should be installed. Based on the response from the
// delegate, KSUpdateActions will be created and run on an internal
// KSActionProcessor.  This action never adds any actions to the processor on
// which it itself is running. This action finishes once all of its subactions
// (if any) complete.
//
// Upon completion, this action's outPipe will contain the number of
// KSUpdateActions enqueued, wrapped in an NSNumber.
//
// Sample code to create a checker and a prompt connected via a pipe.
//
//   KSActionProcessor *ap = ...
//   KSUpdateCheckAction *checker = ...
//
//   KSAction *update = [KSSilentUpdateActionactionWithKeystone:keystone_];
//
//   KSActionPipe *pipe = [KSActionPipe pipe];
//   [checker setOutPipe:pipe];
//   [update setInPipe:pipe];
//
//   [ap enqueueAction:checker];
//   [ap enqueueAction:update];
// 
//   [ap startProcessing];
//
// See KSKeystone.m for another example of using KSSilentUpdateAction.
@interface KSSilentUpdateAction : KSMultiUpdateAction

// See KSMutliUpdateAction's interface

@end
