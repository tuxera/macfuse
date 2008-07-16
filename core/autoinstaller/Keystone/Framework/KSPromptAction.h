//
//  KSPromptAction.h
//  Keystone
//
//  Created by Greg Miller on 2/13/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KSMultiUpdateAction.h"

@class KSKeystone, KSActionProcessor;

// KSPromptAction
//
// This concrete KSMultiAction subclass takes input from its inPipe, which must
// be an array of product dictionaries (see KSServer.h for more details on the
// dictionary format), and messages the keystone_'s delegate to find out which
// of the products in the array should be installed. Based on the response from
// the delegate, KSUpdateActions will be created and run on an internal
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
//   KSPromptAction *prompt = [KSPromptAction actionWithKeystone:keystone_];
//
//   KSActionPipe *pipe = [KSActionPipe pipe];
//   [checker setOutPipe:pipe];
//   [prompt setInPipe:pipe];
//
//   [ap enqueueAction:checker];
//   [ap enqueueAction:prompt];
// 
//   [ap startProcessing];
//
// See KSKeystone.m for another example of using KSPromptAction.
@interface KSPromptAction : KSMultiUpdateAction 

// See KSMultiUpdateAction's interface

@end
