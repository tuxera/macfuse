//
//  KSTicket.h
//  Keystone
//
//  Created by Greg Miller on 12/10/07.
//  Copyright 2007 Google Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KSExistenceChecker;

// POD object that encapsulates information that an application provides when
// "registering" with Keystone. Tickets are a central part of Keystone. Keystone
// maintains one ticket for each registered application. Tickets are how
// Keystone knows what's installed.
// 
// The creation date simply records the date the ticket was created. If a ticket
// is unarchived (from a KSTicketStore), the creationDate_ will be the date the
// ticket was originally created, not the date it was unarchived.
@interface KSTicket : NSObject <NSCoding> {
 @private
  NSString *productID_;  // guid or bundleID
  NSString *version_;
  KSExistenceChecker *existenceChecker_;
  NSURL *serverURL_;
  NSDate *creationDate_;
}

// Returns an autoreleased KSTicket instance initialized with the specified
// arguments. All arguments are required; if any are nil, then nil is returned.
+ (id)ticketWithProductID:(NSString *)productid
                  version:(NSString *)version
         existenceChecker:(KSExistenceChecker *)xc
                serverURL:(NSURL *)serverURL;

// Designated initializer. Returns a KSTicket initialized with the specified
// arguments. All arguments are required; if any are nil, then nil is returned.
- (id)initWithProductID:(NSString *)productid
                version:(NSString *)version
       existenceChecker:(KSExistenceChecker *)xc
              serverURL:(NSURL *)serverURL;

// Returns YES if ticket is equal to the ticket identified by self.
- (BOOL)isEqualToTicket:(KSTicket *)ticket;

// Returns the productID for this ticket.
// We don't know or care if it's a GUID or BundleID
- (NSString *)productID;

// Returns the version for this ticket.
- (NSString *)version;

// Returns the existence checker object for this ticket. This object can be used
// to determine if the application represented by this ticket is still
// installed.
- (KSExistenceChecker *)existenceChecker;

// Returns the server URL to check for updates to the application represented by
// this ticket.
- (NSURL *)serverURL;

// Returns the date this ticket was created.
- (NSDate *)creationDate;

@end
