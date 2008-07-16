//
//  KSKeystone.h
//  Keystone
//
//  Created by Greg Miller on 2/1/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KSUpdateInfo.h"

@class KSTicketStore, KSActionProcessor, KSAction, KSStatsCollection;
@protocol KSCommandRunner;


// KSKeystone (protocol)
//
// Methods of a KSKeystone that are safe to expose on a vended object over
// distributed objects (DO). This protocol simply lists the methods and any
// DO-specific properties (e.g., bycopy, inout) about the methods. Please see
// the actual method declarations in KSKeystone (below) for details about the
// methods' semantics, arguments, and return values.
@protocol KSKeystone <NSObject>
- (id)delegate;
- (void)setDelegate:(in byref id)delegate;
- (void)updateAllProducts;
- (void)updateProductWithProductID:(in bycopy NSString *)productID;
- (BOOL)isUpdating;
- (void)stopAndReset;
- (void)setParams:(in bycopy NSDictionary *)params;
- (void)setStatsCollection:(in byref KSStatsCollection *)statsCollection;
@end


// KSKeystone (class)
//
// This is the main class for interfacing with Keystone.framework. Clients of
// the Keystone.framework, such as KeystoneAgent, should only need to interact
// with this one class. 
//
// Typically, this class will be used to kick off a check for updates for all
// products, a specific product, or simply to return YES/NO whether an update
// is available (not yet implemented). A typical usage scenario to check for 
// updates for all tickets, and install those updates may simly look like:
//
//   id delegate = ... get/create a delegate ...
//   KSKeystone *keystone = [KSKeystone keystoneWithDelegate:delegate];
//   [keystone updateProducts];  // Runs asynchronously
@interface KSKeystone : NSObject <KSKeystone> {
 @private
  KSTicketStore *store_;
  KSActionProcessor *processor_;
  NSDictionary *params_;
  BOOL wasSuccessful_;
  id delegate_;  // weak
}

// Returns the path to the default ticket store. For non-root users, this path
// will usually be ~/Library/Google/Keystone/TicketStore/Keystone.ticketstore.
// For root, it will usually be the equivalent path in /Library. However, the
// default path returned can be overridden with +setDefaultTicketStorePath:.
// This method never returns nil.
+ (NSString *)defaultTicketStorePath;

// Overrides the default ticket store path to be |path|. This method is useful
// for testing because it allows you to change what the system thinks is the 
// default path.
+ (void)setDefaultTicketStorePath:(NSString *)path;

// A convenience method for creating an autoreleased KSKeystone instance that
// will use the default ticket store and the specified |delegate|.
+ (id)keystoneWithDelegate:(id)delegate;

// A convenience method for creating an autoreleased KSKeystone instance that
// will use the specified ticket |store| and |delegate|.
+ (id)keystoneWithTicketStore:(KSTicketStore *)store
                     delegate:(id)delegate;

// The designated initializer. This method returns a KSKeystone instance that 
// will use the specified ticket |store| and |delegate|.
- (id)initWithTicketStore:(KSTicketStore *)store
                 delegate:(id)delegate;

// Returns the KSTicketStore that this KSKeystone is using.
- (KSTicketStore *)ticketStore;

// Returns this KSKeystone's delegate.
- (id)delegate;

// Sets this KSKeystone's delegate. nil is allowed, in which case no delegate is
// used.
- (void)setDelegate:(id)delegate;

// Triggers an update check for all products identified by a ticket in this
// instance's ticket store. Products whose ticket's existence checker indicates
// that the product is no longer installed will be ignored.
- (void)updateAllProducts;

// Triggers an update check for just the one product identified by |productID|.
// Other products are ignored. If the product's ticket's existence checker
// indicates that the product is no longer installed, it will be ignored.
- (void)updateProductWithProductID:(NSString *)productID;

// Returns YES if this KSKeystone is currently doing an udpate check.
- (BOOL)isUpdating;

// Immediately cancels all updates that may be going on currently, and clears
// all pending actions in the action processor. This call resets the KSKeystone
// to its initial state.
- (void)stopAndReset;

// Configure this KSKeystone with a dictionary of parameters indexed
// by the keys in KSKeystoneParameters.h.  These values may come from
// preferences, such as a per-user GUID required by Omaha.
- (void)setParams:(NSDictionary *)params;

// Returns the GTMStatsCollection that the Keystone framework is using for 
// recording stats. Will be nil if one was never set.
- (KSStatsCollection *)statsCollection;

// Sets the stats collector for the Keystone framework to use.
- (void)setStatsCollection:(KSStatsCollection *)stats;

@end  // KSKeystone


// KSKeystoneDelegateMethods
//
// These are methods that a KSKeystone delegate may implement. Each method is
// marked as either required or optional. Optional methods will have some
// "reasonable" default value if not implemented. If a required method is not 
// implemented the program may crash at runtime, produce incorrect results, or
// produce undefined results in any number of ways. Just make sure you implement
// all required methods.
//
// The methods are listed in the relative order in which they're called.
@interface KSKeystone (KSKeystoneDelegateMethods)

// Called when Keystone starts processing an update request.
// 
// Optional.
- (void)keystoneStarted:(KSKeystone *)keystone;

// Sent to the Keystone delegate when product updates are available. The
// |products| array is an array of NSDictionaries, each of with has keys defined
// in KSServer.h. The delegate must return an array containing the product
// dictionaries for the products which are to be prefetched (i.e., downloaded
// before possibly prompting the user about the update). The two most common 
// return values for this delegate method are the following:
//
//   nil      = Don't prefetch anything (same as empty array)
//   products = Prefetch all of the products (this is the default)
//
// Optional - if not implemented, the return value is |products|.
- (NSArray *)keystone:(KSKeystone *)keystone
  shouldPrefetchProducts:(NSArray *)products;

// Sent to the Keystone delegate when product updates are available. The
// |products| array is an array of KSUpdateInfos, each of with has keys defined
// in KSUpdateInfo.h. The delegate should return an array of the products from
// the |products| list that should be installed silently.
//
// Optional - if not implemented, the return value is |products|.
- (NSArray *)keystone:(KSKeystone *)keystone
  shouldSilentlyUpdateProducts:(NSArray *)products;

// Returns a KSCommandRunner instance that can run commands on the delegates 
// behalf. Keystone may call this method multiple times to get a KSCommandRunner
// for running Keystone preinstall and Keystone postinstall scripts (see
// KSInstallAction for more details on these scripts).
//
// The implementation of method should most likely look like the following:
//
//   - (id<KSCommandRunner>)commandRunnerForKeystone:(KSKeystone *)keystone {
//     return [KSTaskCommandRunner commandRunner];
//   }
//
// Required.
- (id<KSCommandRunner>)commandRunnerForKeystone:(KSKeystone *)keystone;

// Sent by |keystone| when the update as defined by |updateInfo| starts.
//
// Optional.
- (void)keystone:(KSKeystone *)keystone
        starting:(KSUpdateInfo *)updateInfo;

// Sent by |keystone| when the update as defined by |updateInfo| has finished.
// |wasSuccess| indicates whether the update was successful, and |wantsReboot|
// indicates whether the update requested that the machine be rebooted.
//
// Optional.
- (void)keystone:(KSKeystone *)keystone
        finished:(KSUpdateInfo *)updateInfo
      wasSuccess:(BOOL)wasSuccess
     wantsReboot:(BOOL)wantsReboot;

// Sent to the Keystone delegate when product updates are available. The
// |products| array is an array of KSUpdateInfos, each of with has keys defined
// in KSUpdateInfo.h. The delegate can use this list of products to optionally
// display UI and ask the user what they want to install, or whatever. The 
// return value should be an array containing the product dictionaries that
// should be updated. If a delegate simply wants to install all of the updates
// they can trivially implement this method to immediately return the same
// |products| array that they were given.
//
// Optional - if not implemented, the return value is |products|.
- (NSArray *)keystone:(KSKeystone *)keystone
 shouldUpdateProducts:(NSArray *)products;

// Called when Keystone is finished processing an update request. |wasSuccess|
// indicates whether the update check was successful or not. An update will fail
// if, for example, there is no network connection. It will NOT fail if an 
// update was downloaded and that update's installer happened to fail.
// 
// Optional.
- (void)keystoneFinished:(KSKeystone *)keystone wasSuccess:(BOOL)wasSuccess;

@end  // KSKeystoneDelegateMethods


// KSKeystoneActionPrivateCallbackMethods
//
// These methods provide a way for KSActions created by this KSKeystone to
// indirectly communicate with this KSKeystone's delegate. Clients of KSKeystone
// should *NEVER* call these methods directly. Consider them to be private.
@interface KSKeystone (KSKeystoneActionPrivateCallbackMethods)

// Calls the KSKeystone delegate's -keystone:shouldPrefetchProducts: method if
// it is implemented. Otherwise, the |products| argument is returned.
- (NSArray *)action:(KSAction *)action
shouldPrefetchProducts:(NSArray *)products;

// Calls the KSKeystone delegate's -keystone:shouldSilentlyUpdateProducts:
// method if the delegate implements it. Otherwise, the |products| argument is
// returned.
- (NSArray *)action:(KSAction *)action 
  shouldSilentlyUpdateProducts:(NSArray *)products;

// Calls the KSKeystone delegate's -commandRunnerForKeystone: method. The
// the delegate is required to implement this method. (though, if the delegate
// doesn't implement it, we'll be nice and return nil anyway).
- (id<KSCommandRunner>)commandRunnerForAction:(KSAction *)action;

// Calls the KSKeystone delegate's -keystone:starting: method.
// The delegate does not need to implement this method.
- (void)action:(KSAction *)action
      starting:(KSUpdateInfo *)updateInfo;

// Calls the KSKeystone delegate's -keystone:finished:wasSuccess:wantsReboot:
// method. The delegate does not need to implement this method.
- (void)action:(KSAction *)action
      finished:(KSUpdateInfo *)updateInfo
    wasSuccess:(BOOL)wasSuccess
   wantsReboot:(BOOL)wantsReboot;

// Calls the KSKeystone delegate's -keystone:shouldUpdateProducts: method if 
// the delegate implements it. Otherwise, the |products| argument is returned.
- (NSArray *)action:(KSAction *)action 
  shouldUpdateProducts:(NSArray *)products;

@end  // KSKeystoneActionPrivateCallbackMethods
