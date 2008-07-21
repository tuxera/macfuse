//
//  KSKeystoneVendor.m
//  Keystone
//
//  Created by Greg Miller on 2/20/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import "KSKeystoneVendor.h"
#import "KSKeystoneBroker.h"
#import "GTMLogger.h"


@implementation KSKeystoneVendor

+ (id)vendorWithKeystoneBroker:(KSKeystoneBroker *)keystoneBroker
                          name:(NSString *)name {
  return [[[self alloc] initWithKeystoneBroker:keystoneBroker
                                          name:name] autorelease];
}

- (id)initWithKeystoneBroker:(KSKeystoneBroker *)keystoneBroker
                        name:(NSString *)name {
  if ((self = [super init])) {
    keystoneBroker_ = [keystoneBroker retain];
    name_ = [name copy];
    if (keystoneBroker_ == nil || [name_ length] == 0) {
      [self release];
      return nil;
    }
  }
  return self;
}

- (void)dealloc {
  [self stopVending];  // releases connection_
  [keystoneBroker_ release];
  [name_ release];
  [super dealloc];
}

- (KSKeystoneBroker *)keystoneBroker {
  return keystoneBroker_;
}

- (NSString *)name {
  return name_;
}

- (BOOL)isVending {
  return isVending_;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@:%p vendedKeystoneBroker=%@ name=%@>",
          [self class], self, keystoneBroker_, name_];
}

- (BOOL)startVending {
  // Just return if we're already vending a KeystoneBroker
  if (isVending_)
    return YES;
  
  _GTMDevAssert(keystoneBroker_ != nil, @"keystoneBroker_ must not be nil");
  _GTMDevAssert(name_ != nil, @"name_ must not be nil");
  _GTMDevAssert(connection_ == nil, @"connection_ must be nil at this point");
    
  connection_ = [[NSConnection alloc] initWithReceivePort:[NSMachPort port]
                                                 sendPort:nil];
  [connection_ setDelegate:self];
  // Sets the request timeouts in seconds. If a request can't be sent within
  // this time period, an exception is raised. This timeout does not include the
  // time taken to receive a response; that is covered by the /reply/ timeout.
  //
  // We don't set the reply timeout, so we get the default of the max possible.
  // We need a really long reply timeout because we may send messages to the 
  // Keystone agent and it may have to wait for a *long* time for the user to 
  // respond (maybe they didn't see the agent's UI window).
  [connection_ setRequestTimeout:60];

  // Set the connection's root object to be the protocol checker so that only
  // methods listed in the specified protocol are available via DO.
  NSProtocolChecker *checker =
  [NSProtocolChecker protocolCheckerWithTarget:keystoneBroker_
                                      protocol:@protocol(KSKeystoneBroker)];
  [connection_ setRootObject:checker];
  
  isVending_ = YES;
  if ([connection_ registerName:name_]) {
    // Log at error level so this always shows up in the output.
    GTMLoggerError(@"Vending %@ on %@ with %@",
                   keystoneBroker_, name_, connection_);
  } else {
    GTMLoggerError(@"Failed to vend %@ on %@ with %@",
                   keystoneBroker_, name_, connection_);
    // This will reset isVending_ to NO
    [self stopVending];
  }
  
  return isVending_;
}

- (void)stopVending {
  if (!isVending_)
    return;
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  // We need to log this message before tearing down the connection because the
  // |keystoneBroker_|'s delegate might be an NSDistantObject which would be 
  // invalid after we tear down the connection (which would make our 
  // -description call blow up).
  GTMLoggerInfo(@"Stopping vending %@ on %@", keystoneBroker_, name_); 

  // NSConnection doesn't unregister the port with the port name server (but it
  // should). The docs say that setting the registered name to nil should work,
  // and that does indeed cause NSConnection to try to unregister, however, the
  // port name sever's -removePortForName: method always returns NO.  Currently
  // (10.5.2), the only way to cause the port to be unregistered is to actually
  // destroy the registered Mach port. So, we'll reach into NSConnection and do
  // that.  --  Radar 5756171
  [connection_ registerName:nil];
  [[connection_ receivePort] invalidate];
  [connection_ invalidate];
  [connection_ release];
  connection_ = nil;
  
  isVending_ = NO;
}

- (BOOL)connection:(NSConnection *)connection
shouldMakeNewConnection:(NSConnection *)newConnection {  
  
  ++childConnections_;
  GTMLoggerInfo(@"Making new child connection (#%d)", childConnections_);    
  
  // Listen for connection death notifications from the child connection
  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(connectionDied:)
             name:NSConnectionDidDieNotification
           object:newConnection];
  
  return YES;
}

- (void)connectionDied:(NSNotification *)notification {
  NSConnection *deadConnection = [notification object];
  
  --childConnections_;
  GTMLoggerInfo(@"Connection died (#%d)", childConnections_);
  
  [[NSNotificationCenter defaultCenter]
      removeObserver:self
                name:nil
              object:deadConnection];
  
  if (childConnections_ == 0) {
    GTMLoggerInfo(@"Last child connection closed; forcing unlock of broker");
    // The last child connection died, so nobody could possibly be using the
    // KSKeystone from the keystoneBroker_. We force unlock the keystoneBroker_
    // in this case to make sure that things are clear and ready for a new
    // connection. This helps in the case where someone held the broker's lock
    // but they crashed before unlocking it.
    [keystoneBroker_ performSelectorOnMainThread:@selector(forceUnlock)
                                      withObject:nil
                                   waitUntilDone:YES];
  }
}

@end
