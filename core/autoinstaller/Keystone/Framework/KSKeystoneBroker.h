//
//  KSKeystoneBroker.h
//  Keystone
//
//  Created by Greg Miller on 3/18/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KSKeystone;


// KSKeystoneBroker (protocol)
//
// Protocol that declares the interface (and DO modifiers) for an object that
// can act as a broker for a KSKeystone instance. Basically, a Keystone broker
// must provide exclusive access to a KSKeystone instance.
@protocol KSKeystoneBroker

// Returns a KSKeystone instance to use exclusively. The instance will not be
// returned to anyone else until the caller returns the instance back to the
// broker with the -returnKeystone: message. If no KSKeystone instance is
// available, nil will be returned.
- (out byref KSKeystone *)claimKeystone;

// Returns the specified |keystone| instance back to the broker. This makes this
// instance available to other callers that call -claimKeystone.
- (void)returnKeystone:(KSKeystone *)keystone;
@end


// KSKeystoneBroker (class)
//
// Provides exclusive access to one KSKeystone instance.
// 
// Sample usage:
//
//   KSKeystone *keystone = ...
//   KSKeystoneBroker *broker =
//     [KSKeystoneBroker brokerWithKeystone:keystone];
//   
//   ...
//   KSKeystone *myKeystone = [broker claimKeystone];
//   ...
//   [broker returnKeystone:myKeystone];
//
@interface KSKeystoneBroker : NSObject <KSKeystoneBroker> {
 @private
  KSKeystone *keystone_;
  NSLock *lock_;
}

// Returns an autoreleased instance that will allow exclusive access to
// |keystone|.
+ (id)brokerWithKeystone:(KSKeystone *)keystone;

// Designated initializer. Returns a KSKeystoneBroker that will allow
// exclusive access to |keystone|.
- (id)initWithKeystone:(KSKeystone *)keystone;

// Forcefully unlocks the lock, and stops and resets the keystone_ instance.
- (void)forceUnlock;

@end
