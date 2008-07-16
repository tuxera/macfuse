//
//  KSTicketStore.h
//  Keystone
//
//  Created by Greg Miller on 12/10/07.
//  Copyright 2007 Google Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KSTicket;

// Encapsulates a persistent storage mechanism for saving and retrieving
// KSTicket objects. Tickets are indexed by their productID, so no two tickets 
// can exist in the same store with the same productID. Tickets are indexed in a
// case insensitive but case preserving manner: a ticket stored with a product 
// ID of "foo" could be replaced by a ticket with a product ID of "Foo". If a 
// ticket is stored and another ticket is already stored with the same 
// productID, then the new ticket replaces the previously stored one.
@interface KSTicketStore : NSObject {
 @private
  NSString *path_;
}

// Returns a ticket store stored at |path|.
+ (id)ticketStoreWithPath:(NSString *)path;
// Designated initializer.
- (id)initWithPath:(NSString *)path;

// Returns the path where this ticket store is stored.
- (NSString *)path;

// Returns the number of tickets currently stored.
- (int)ticketCount;

// Returns all tickets.
- (NSArray *)tickets;

// Returns the ticket associated with |productID|.
- (KSTicket *)ticketForProductID:(NSString *)productID;

// Returns YES if |ticket| was successfully added to the store. The stored
// ticket is indexed by a lower-case version of its product ID. So storing
// a ticket with a product ID of "Foo" would replace a previously stored ticket
// with a product ID of "foo".
- (BOOL)storeTicket:(KSTicket *)ticket;

// Returns YES if |ticket| was successfully removed form the store.
- (BOOL)deleteTicket:(KSTicket *)ticket;

// Returns YES if the ticket identified by |productID| was removed from the store.
- (BOOL)deleteTicketForProductID:(NSString *)productID;

@end


// A category to group methods that are related to querying an array for tickets
// that match a certain criteria. In addition to the methods specified here, you
// can also use the -[KSTicketStore tickets] method to get all of the tickets,
// then use -[NSArray filteredArrayUsingPredicate:].
@interface NSArray (TicketRetrieving)

// Returns a dictionary that groups tickets by their server URL. The keys in the
// dictionary are NSURLs, and the values are arrays of tickets that use that 
// server URL. This method must only be called on an homogeneous array of
// KSTickets.
- (NSDictionary *)ticketsByURL;

@end
