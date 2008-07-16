//
//  KSPrefetchAction.h
//  Keystone
//
//  Created by Greg Miller on 2/14/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KSMultiAction.h"

@class KSKeystone, KSActionProcessor;

// KSPrefetchAction
//
// This concrete KSMultiAction subclass that takes input from its inPipe, which
// must be an array of product dictionaries (see KSServer.h for more details on
// the dictionary format), and messages the keystone_'s delegate to find out
// which of the products in the array should be prefetched. Based on the
// response from the delegate, KSDownloadActions will be created and run on an
// internal KSActionProcessor.  This action never adds any actions to the
// processor on which it itself is running. This action finishes once all of its
// subactions (if any) complete.
//
// This class can be used to download product updates before prompting the user
// to install the update. This way, when the user does the install, they do not
// need to wait for the download to complete.
//
// This action always sets its outPipe's contents to be the exact same as its
// inPipe contents.
//
// Sample code to create a checker and a prefetcher connected via a pipe.
//
//   KSActionProcessor *ap = ...
//   KSUpdateCheckAction *checker = ...
//
//   KSPrefetchAction *prefetch = [KSPromptAction actionWithKeystone:keystone_];
//
//   KSActionPipe *pipe = [KSActionPipe pipe];
//   [checker setOutPipe:pipe];
//   [prefetch setInPipe:pipe];
//
//   [ap enqueueAction:checker];
//   [ap enqueueAction:prefetch];
// 
//   [ap startProcessing];
//
// See KSKeystone.m for another example of using KSPrefetchAction.
@interface KSPrefetchAction : KSMultiAction {
 @private
  KSKeystone *keystone_;
}

// Returns an autoreleased KSPrefetchAction associated with |keystone|
+ (id)actionWithKeystone:(KSKeystone *)keystone;

// Designated initializer. Returns a KSPrefetchAction associated with |keystone|
- (id)initWithKeystone:(KSKeystone *)keystone;

@end
