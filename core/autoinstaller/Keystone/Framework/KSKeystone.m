//
//  KSKeystone.m
//  Keystone
//
//  Created by Greg Miller on 2/1/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import "KSKeystone.h"

#import <unistd.h>

#import "KSTicketStore.h"
#import "KSFrameworkStats.h"
#import "KSActionProcessor.h"
#import "KSCheckAction.h"
#import "KSPrefetchAction.h"
#import "KSSilentUpdateAction.h"
#import "KSPromptAction.h"
#import "KSActionPipe.h"
#import "KSKeystoneParameters.h"
#import "GTMLogger.h"
#import "GTMPath.h"
#import "GTMNSString+FindFolder.h"


@interface KSKeystone (PrivateMethods)

// Tiggers an update check for all of the tickets in the specified array. This
// method is called by -updateAllProducts and -updateProductWithProductID: to
// do the real work.
- (void)triggerUpdateForTickets:(NSArray *)tickets;

@end

// The user-defined default ticket store path. If this value is nil, then the
// +defaultTicketStorePath method will generate a nice default value. This
// variable is typically only used in testing situations.
static NSString *gDefaultTicketStorePath = nil;

@implementation KSKeystone

// Returns [~]/Library/Google/Keystone/TicketStore/Keystone.ticketstore
+ (NSString *)defaultTicketStorePath {
  if (gDefaultTicketStorePath) return gDefaultTicketStorePath;
  // COV_NF_START
  short domain = geteuid() == 0 ? kLocalDomain : kUserDomain;
  NSString *library =
    [NSString gtm_stringWithPathForFolder:kDomainLibraryFolderType
                                 inDomain:domain
                                 doCreate:YES];
  
  GTMPath *path = [[[[[GTMPath pathWithFullPath:library]
                      createDirectoryName:@"Google" mode:0755]
                     createDirectoryName:@"GoogleSoftwareUpdate" mode:0755]
                    createDirectoryName:@"TicketStore" mode:0700]
                   createFileName:@"Keystone.ticketstore" mode:0700];
  
  return [path fullPath];
  //COV_NF_END
}

+ (void)setDefaultTicketStorePath:(NSString *)path {
  [gDefaultTicketStorePath autorelease];
  gDefaultTicketStorePath = [path copy];
}

+ (id)keystoneWithDelegate:(id)delegate {
  NSString *storePath = [self defaultTicketStorePath];
  KSTicketStore *store = [KSTicketStore ticketStoreWithPath:storePath];
  return [self keystoneWithTicketStore:store delegate:delegate];
}

+ (id)keystoneWithTicketStore:(KSTicketStore *)store
                     delegate:(id)delegate {
  return [[[self alloc] initWithTicketStore:store
                                   delegate:delegate] autorelease];
}

- (id)init {
  return [self initWithTicketStore:nil delegate:nil];
}

- (id)initWithTicketStore:(KSTicketStore *)store 
                 delegate:(id)delegate {
  if ((self = [super init])) {
    store_ = [store retain];
    [self setDelegate:delegate];
    [self stopAndReset];
    if (store_ == nil) {
      GTMLoggerDebug(@"error: created with nil ticket store");
      [self release];
      return nil;
    }
  }
  params_ = [[NSDictionary alloc] init];
  return self;
}

- (void)dealloc {
  [params_ release];
  [store_ release];
  [processor_ setDelegate:nil];
  [processor_ release];
  [super dealloc];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@:%p store=%@ delegate=%@>",
          [self class], self, store_, delegate_];
}

- (KSTicketStore *)ticketStore {
  return store_;
}

- (id)delegate {
  return delegate_;
}

- (void)setDelegate:(id)delegate {
  // We must retain/release our delegate because the delegate_ may be an NSProxy
  // which may not exist for the life of this KSKeystone. In reality, this only
  // appears to be a problem on Tiger, but, we have to work on Tiger, too.
  @try {
    [delegate_ autorelease];
    delegate_ = [delegate retain];
  // COV_NF_START
  }
  @catch (id ex) {
    GTMLoggerError(@"Caught exception setting delegate: %@", ex);
  }
  // COV_NF_END
}

// Triggers an update for all products in the main ticket store |store_|
- (void)updateAllProducts {
  _GTMDevAssert(store_ != nil, @"store_ must not be nil");
  [self triggerUpdateForTickets:[store_ tickets]];
}

- (void)updateProductWithProductID:(NSString *)productID {
  _GTMDevAssert(store_ != nil, @"store_ must not be nil");  
  KSTicket *ticket = [store_ ticketForProductID:productID];
  if (ticket == nil) {
    GTMLoggerInfo(@"No ticket for product with Product ID %@", productID);
    return;
  }
  
  NSArray *oneTicket = [NSArray arrayWithObject:ticket];
  [self triggerUpdateForTickets:oneTicket];
}

- (BOOL)isUpdating {
  return [processor_ isProcessing];
}

- (void)stopAndReset {
  [processor_ stopProcessing];
  [processor_ autorelease];
  processor_ = [[KSActionProcessor alloc] initWithDelegate:self];
}

- (void)setParams:(NSDictionary *)params {
  [params_ autorelease];
  params_ = [params retain];
}

- (KSStatsCollection *)statsCollection {
  return [KSFrameworkStats sharedStats];
}

- (void)setStatsCollection:(KSStatsCollection *)statsCollection {
  [KSFrameworkStats setSharedStats:statsCollection];
}

//
// KSActionProcessor delegate callbacks
//

- (void)processingStarted:(KSActionProcessor *)processor {
  GTMLoggerInfo(@"processor=%@", processor);
  @try {
    if ([delegate_ respondsToSelector:@selector(keystoneStarted:)])
      [delegate_ keystoneStarted:self];
  }
  @catch (id ex) {
    GTMLoggerError(@"Caught exception talking to delegate: %@", ex);
  }
}

- (void)processingStopped:(KSActionProcessor *)processor {
  GTMLoggerInfo(@"processor=%@, wasSuccesful_=%d", processor, wasSuccessful_);
  @try {
    if ([delegate_ respondsToSelector:@selector(keystoneFinished:wasSuccess:)])
      [delegate_ keystoneFinished:self wasSuccess:wasSuccessful_];
  }
  @catch (id ex) {
    GTMLoggerError(@"Caught exception talking to delegate: %@", ex);
  }
}

- (void)processor:(KSActionProcessor *)processor
   startingAction:(KSAction *)action {
  GTMLoggerInfo(@"processor=%@, action=%@", processor, action);
}

- (void)processor:(KSActionProcessor *)processor
   finishedAction:(KSAction *)action
     successfully:(BOOL)wasOK {
  GTMLoggerInfo(@"processor=%@, action=%@, wasOK=%d", processor, action, wasOK);
  if (!wasOK) {
    // If any of these actions fail (in reality, the only one that can possibly
    // fail is the KSCheckAction), we indicate that this fetch was not
    // successful, and we stop everything.
    wasSuccessful_ = NO;
    [self stopAndReset];
  }
}

// We override this NSObject method to ensure that KSKeystone instances are
// always sent over DO byref, wrapped in an NSProtocolChecker. This means that
// KSKeystone delegates who access us via a vended DO object will only have
// access to the methods declared in the KSKeystone protocol (e.g., they
// will NOT have access to the -ticketStore method).
- (id)replacementObjectForPortCoder:(NSPortCoder *)encoder {
  NSProtocolChecker *pchecker =
    [NSProtocolChecker protocolCheckerWithTarget:self
                                        protocol:@protocol(KSKeystone)];
  return [NSDistantObject proxyWithLocal:pchecker
                              connection:[encoder connection]];
}

@end  // KSKeystone


@implementation KSKeystone (KSKeystoneActionPrivateCallbackMethods)

- (NSArray *)action:(KSAction *)action shouldPrefetchProducts:(NSArray *)products {
  @try {
    if ([delegate_ respondsToSelector:@selector(keystone:shouldPrefetchProducts:)])
      return [delegate_ keystone:self shouldPrefetchProducts:products];
  }
  @catch (id ex) {
    GTMLoggerError(@"Caught exception talking to delegate: %@", ex);
  }
  return products;  // if not implemented, assume we want to prefetch everything
}

- (NSArray *)action:(KSAction *)action 
  shouldSilentlyUpdateProducts:(NSArray *)products {
  @try {
    if ([delegate_ respondsToSelector:@selector(keystone:shouldSilentlyUpdateProducts:)])
      return [delegate_ keystone:self shouldSilentlyUpdateProducts:products];
  }
  @catch (id ex) {
    GTMLoggerError(@"Caught exception talking to delegate: %@", ex);
  }
  return products;  // if not implemented, assume we want to update everything
}
- (id<KSCommandRunner>)commandRunnerForAction:(KSAction *)action {
  @try {
    // The delegate is required to implement this method, but we'll go the extra
    // 11 feet to and make sure before calling it.
    if ([delegate_ respondsToSelector:@selector(commandRunnerForKeystone:)])
      return [delegate_ commandRunnerForKeystone:self];
  }
  @catch (id ex) {
    GTMLoggerError(@"Caught exception talking to delegate: %@", ex);
  }
  return nil;
}

- (void)action:(KSAction *)action
      starting:(KSUpdateInfo *)updateInfo {
  @try {
    // Inform the delegate that we are starting to update something
    if ([delegate_ respondsToSelector:@selector(keystone:starting:)])
      [delegate_ keystone:self starting:updateInfo];
  }
  @catch (id ex) {
    GTMLoggerError(@"Caught exception talking to delegate: %@", ex);
  }
}

- (void)action:(KSAction *)action
      finished:(KSUpdateInfo *)updateInfo
    wasSuccess:(BOOL)wasSuccess
   wantsReboot:(BOOL)wantsReboot {
  @try {
    // Inform the delegate that we finished updating something
    if ([delegate_ respondsToSelector:
         @selector(keystone:finished:wasSuccess:wantsReboot:)])
      [delegate_ keystone:self
                 finished:updateInfo
               wasSuccess:wasSuccess
              wantsReboot:wantsReboot];
  }
  @catch (id ex) {
    GTMLoggerError(@"Caught exception talking to delegate: %@", ex);
  }
}

- (NSArray *)action:(KSAction *)action shouldUpdateProducts:(NSArray *)products {
  @try {
    if ([delegate_ respondsToSelector:@selector(keystone:shouldUpdateProducts:)])
      return [delegate_ keystone:self shouldUpdateProducts:products];
  }
  @catch (id ex) {
    GTMLoggerError(@"Caught exception talking to delegate: %@", ex);
    products = nil;
  }
  return products;  // if not implemented, assume we want to update everything
}

@end  // KSKeystoneActionPrivateCallbackMethods


@implementation KSKeystone (PrivateMethods)

- (void)triggerUpdateForTickets:(NSArray *)tickets {
  _GTMDevAssert(processor_ != nil, @"processor must not be nil");

  // Will be set to NO if any of the KSActions fail. But note that the only 
  // one of these KSActions that can ever fail is the KSCheckAction.
  wasSuccessful_ = YES;
  
  // Build a KSMultiAction pipeline with output flowing as indicated:
  //
  // KSCheckAction -> KSPrefetchAction -> KSSilentUpdateAction -> KSPromptAction
  
  KSAction *check    = [KSCheckAction actionWithTickets:tickets params:params_];
  KSAction *prefetch = [KSPrefetchAction actionWithKeystone:self];
  KSAction *silent   = [KSSilentUpdateAction actionWithKeystone:self];
  KSAction *prompt   = [KSPromptAction actionWithKeystone:self];
  
  [KSActionPipe bondFrom:check to:prefetch];
  [KSActionPipe bondFrom:prefetch to:silent];
  [KSActionPipe bondFrom:silent to:prompt];
  
  [processor_ enqueueAction:check];
  [processor_ enqueueAction:prefetch];
  [processor_ enqueueAction:silent];
  [processor_ enqueueAction:prompt];
  
  [processor_ startProcessing];
}

@end  // PrivateMethods
