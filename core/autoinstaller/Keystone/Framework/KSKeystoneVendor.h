//
//  KSKeystoneVendor.h
//  Keystone
//
//  Created by Greg Miller on 2/20/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KSKeystoneBroker;

// KSKeystoneVendor
//
// This class vends a KSKeystone instance indirectly, by way of a
// KSKeystoneBroker instance. The actual object that's vended on a Mach port
// using Cocoa's distributed objects is a KSKeystoneBroker that allows 
// exclusive access to a KSKeystone instance. Both of the KSKeystoneBroker and
// KSKeystone classes are wrapped in NSProtocolCheckers when sent over the wire
// to secure their exposed interfaces.
//
// To use this you simply need to provide a KSKeystone instance to be vended and
// an NSString to use as the name of the "service" which you are providing.
// Clients will use this name string to lookup the service and connect.
// 
// Sample code:
//
//   // Vending a KSKeystoneBroker
//
//   KSKeystone *keystone = ...
//   KSKeystoneBroker *broker = ...
//   KSKeystoneVendor *vendor =
//     [KSKeystoneVendor vendorWithKeystoneBroker:broker
//                                           name:@"com.google.blah"];
//  
//   if (![vendor startVending]) {
//     // Handle error
//   }
//
//   ...
// 
//   // Client side
//
//   KSKeystoneBroker *remoteBroker = (KSKeystoneBroker *)
//   [NSConnection rootProxyForConnectionWithRegisteredName:@"com.google.blah"
//                                                     host:nil];
//
//   KSKeystone *remoteKeystone = [remoteBroker claimKeystone];
//   [remoteKeystone updateAllProducts];  // Use remote object via DO
//   [remoteBroker returnKeystone:remoteKeystone];
// 
@interface KSKeystoneVendor : NSObject {
 @private
  KSKeystoneBroker *keystoneBroker_;
  NSString *name_;
  NSConnection *connection_;
  int childConnections_;
  BOOL isVending_;
}

// Convenience method that returns an autoreleased KSKeystoneVendor. See the 
// designated initializer for a description of the args.
+ (id)vendorWithKeystoneBroker:(KSKeystoneBroker *)keystoneBroker
                          name:(NSString *)name;

// Designated initializer. Returns a KSKeystoneVendor that will vend |keystone|
// via Distributed Objects, and will make the DO service available via the name
// |name|. Neither argument is allowed to be nil.
- (id)initWithKeystoneBroker:(KSKeystoneBroker *)keystoneBroker
                        name:(NSString *)name;

// Returns the KSKestone instance that is to be vended. This instance may
// currently be vended (if -startVending has already been called), or it may be
// the instance that will be vended once -startVending is finally called.
- (KSKeystoneBroker *)keystoneBroker;

// Returns the name under which the vended KSKeystone will be available. Clients
// can pass this string to NSConnection to connect to this vended object.
- (NSString *)name;

// Returns YES if the KSKeystone is currently being vended. NO otherwise.
- (BOOL)isVending;

// Starts vending the KSKeystone. If the KSKeystone is already being vended,
// this method just returns YES;
- (BOOL)startVending;

// Stops vending the KSKeystone. If the KSKeystone was not being vended, this
// method does nothing. It is safe to startVending then stopVending, then start
// vending again.
- (void)stopVending;

@end
