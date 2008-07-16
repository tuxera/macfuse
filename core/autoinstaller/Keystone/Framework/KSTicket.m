//
//  KSTicket.m
//  Keystone
//
//  Created by Greg Miller on 12/10/07.
//  Copyright 2007 Google Inc. All rights reserved.
//

#import "KSTicket.h"
#import "KSExistenceChecker.h"


@implementation KSTicket

+ (id)ticketWithProductID:(NSString *)productid
                  version:(NSString *)version
         existenceChecker:(KSExistenceChecker *)xc
                serverURL:(NSURL *)serverURL {

  return [[[self alloc] initWithProductID:productid
                                  version:version
                         existenceChecker:xc
                                serverURL:serverURL] autorelease];
}

- (id)init {
  return [self initWithProductID:nil
                    version:nil
           existenceChecker:nil
                  serverURL:nil];
}

- (id)initWithProductID:(NSString *)productid
           version:(NSString *)version
  existenceChecker:(KSExistenceChecker *)xc
         serverURL:(NSURL *)serverURL {

  if ((self = [super init])) {
    productID_ = [productid copy];
    version_ = [version copy];
    existenceChecker_ = [xc retain];
    serverURL_ = [serverURL retain];
    creationDate_ = [[NSDate alloc] init];

    // ensure that no ivars are nil
    if (productID_ == nil || version_ == nil ||
        existenceChecker_ == nil || serverURL == nil) {
      [self release];
      return nil;
    }
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)coder {
  if ((self = [super init])) {
    productID_ = [[coder decodeObjectForKey:@"product_id"] retain];
    version_ = [[coder decodeObjectForKey:@"version"] retain];
    existenceChecker_ = [[coder decodeObjectForKey:@"existence_checker"] retain];
    serverURL_ = [[coder decodeObjectForKey:@"server_url"] retain];
    creationDate_ = [[coder decodeObjectForKey:@"creation_date"] retain];
  }
  return self;
}

- (void)dealloc {
  [productID_ release];
  [version_ release];
  [existenceChecker_ release];
  [serverURL_ release];
  [creationDate_ release];
  [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:productID_ forKey:@"product_id"];
  [coder encodeObject:version_ forKey:@"version"];
  [coder encodeObject:existenceChecker_ forKey:@"existence_checker"];
  [coder encodeObject:serverURL_ forKey:@"server_url"];
  [coder encodeObject:creationDate_ forKey:@"creation_date"];
}

- (unsigned)hash {
  return [productID_ hash] + [version_ hash] + [existenceChecker_ hash]
       + [serverURL_ hash] + [creationDate_ hash];
}

- (BOOL)isEqual:(id)other {
  if (other == self)
    return YES;
  if (!other || ![other isKindOfClass:[self class]])
    return NO;
  return [self isEqualToTicket:other];
}

- (BOOL)isEqualToTicket:(KSTicket *)ticket {
  if (ticket == self)
    return YES;
  if (![productID_ isEqualToString:[ticket productID]])
    return NO;
  if (![version_ isEqualToString:[ticket version]])
    return NO;
  if (![existenceChecker_ isEqual:[ticket existenceChecker]])
    return NO;
  if (![serverURL_ isEqual:[ticket serverURL]])
    return NO;
  if (![creationDate_ isEqual:[ticket creationDate]])
    return NO;
  return YES;
}

- (NSString *)description {
  return [NSString stringWithFormat:
          @"<%@:%p\n\tproductID=%@\n\tversion=%@\n\t"
          @"xc=%@\n\turl=%@\n\tcreationDate=%@>",
          [self class], self, productID_, 
          version_, existenceChecker_, serverURL_, creationDate_];
}

- (NSString *)productID {
  return productID_;
}

- (NSString *)version {
  return version_;
}

- (KSExistenceChecker *)existenceChecker {
  return existenceChecker_;
}

- (NSURL *)serverURL {
  return serverURL_;
}

- (NSDate *)creationDate {
  return creationDate_;
}

@end
