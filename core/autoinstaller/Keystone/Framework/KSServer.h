//
//  KSServer.h
//  KeystoneServer
//
//  Created by Greg Miller on 12/18/07.
//  Copyright 2007 Google Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


// KSServer
//
// *Abstract* class for dealing with specific types of "Keystone servers".
// Subclasses will contain all of the information specific to a given Keystone
// server type. Subclasses should be able to create one or more NSURLRequest
// objects for a specific server from the list of tickets. They must also be
// able to convert from an NSURLResponse and a blob of data into an array of
// KSUpdateInfos representing the response from the server in a server agnostic
// way. A "KSServer" represents a specific instance (because of the URL) of some
// type of server.
//
// See also KSUpdateInfo.h
@interface KSServer : NSObject {
 @private
  NSURL *url_;
}

// Designated initializer.
- (id)initWithURL:(NSURL *)url;

// Returns the URL of this server.
- (NSURL *)url;

// Returns an array of NSURLRequest objects for the given |tickets|.
// Array may contain only one request, or may be nil.
- (NSArray *)requestsForTickets:(NSArray *)tickets;

// Returns an array of KSUpdateInfo dictionaries representing the results from a
// server in a server agnostic way. The keys for the dictionaries are declared
// in KSUpdateInfo.h.
- (NSArray *)updateInfosForResponse:(NSURLResponse *)response data:(NSData *)data;

// Returns a pretty-printed version of the specified response and data.
- (NSString *)prettyPrintResponse:(NSURLResponse *)response data:(NSData *)data;

@end
