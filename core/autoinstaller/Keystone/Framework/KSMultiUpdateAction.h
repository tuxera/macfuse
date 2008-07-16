//
//  KSMultiUpdateAction.h
//  Keystone
//
//  Created by Greg Miller on 2/26/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KSMultiAction.h"

@class KSKeystone;

// KSMultiUpdateAction
//
// Abstract action that encapsulates running multiple sub-KSUpdateActions. Two
// concrete subclasses of this class are KSSilentUpdateAction and
// KSPromptAction, each of which differ only in how they figure out which of
// the available updates should be installed.
@interface KSMultiUpdateAction : KSMultiAction {
 @private
  KSKeystone *keystone_;
}

// Returns an autoreleased action associated with the given |keystone|
+ (id)actionWithKeystone:(KSKeystone *)keystone;

// Designated initializer. Returns an action associated with |keystone|
- (id)initWithKeystone:(KSKeystone *)keystone;

// Returns the KSKeystone instance for this KSMultiUpdateAction
- (KSKeystone *)keystone;

@end


// These methods MUST be implemented by subclasses. These methods are called
// from the -performAction method and are required.
@interface KSMultiUpdateAction (PureVirtualMethods)

// Given an array of KSUpdateInfos. Returns an array of KSUpdateInfos for the
// products that should be updated.
- (NSArray *)productsToUpdateFromAvailable:(NSArray *)availableUpdates;

@end
