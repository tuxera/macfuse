//
//  KSMemoryTicketStore.m
//  Keystone
//
//  Created by Greg Miller on 7/7/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import "KSMemoryTicketStore.h"
#import "KSTicket.h"


@implementation KSMemoryTicketStore

- (id)initWithPath:(NSString *)path {
  NSString *dummy = [NSString stringWithFormat:@"KSMemoryTicketStore-%p", self];
  if ((self = [super initWithPath:dummy])) {
    if (path != nil) {
      [self release];
      return nil;
    }
    tickets_ = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (void)dealloc {
  [tickets_ release];
  [super dealloc];
}

- (NSArray *)tickets {
  NSArray *values = nil;
  @synchronized (tickets_) {
    values = [tickets_ allValues];
  }
  return values;
}

- (KSTicket *)ticketForProductID:(NSString *)productid {
  if (productid == nil) return nil;
  KSTicket *ticket = nil;
  @synchronized (tickets_) {
    ticket = [tickets_ objectForKey:[productid lowercaseString]];
  }
  return ticket;
}

- (BOOL)storeTicket:(KSTicket *)ticket {
  if (ticket == nil) return NO;  
  @synchronized (tickets_) {
    [tickets_ setObject:ticket forKey:[[ticket productID] lowercaseString]];
  }
  return YES;
}

- (BOOL)deleteTicket:(KSTicket *)ticket {
  if (ticket == nil) return NO;
  @synchronized (tickets_) {
    [tickets_ removeObjectForKey:[[ticket productID] lowercaseString]];
  }
  return YES;
}

@end
