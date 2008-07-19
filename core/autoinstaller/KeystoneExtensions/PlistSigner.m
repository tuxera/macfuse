//
//  SignedPlist.m
//  autoinstaller
//
//  Created by Greg Miller on 7/18/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import "PlistSigner.h"
#import "Signer.h"


static NSString *const kSignatureKey = @"Signature";


@interface PlistSigner (PrivateMethods)
- (void)setPlist:(NSDictionary *)plist;
@end


@implementation PlistSigner

- (id)init {
  return [self initWithSigner:nil plist:nil];
}

- (id)initWithSigner:(Signer *)signer plist:(NSDictionary *)plist {
  if ((self = [super init])) {
    signer_ = [signer retain];
    [self setPlist:plist];
    if (signer_ == nil || plist_ == nil) {
      [self release];
      return nil;
    }
  }
  return self;
}

- (void)dealloc {
  [signer_ release];
  [plist_ release];
  [super dealloc];
}

- (NSDictionary *)plist {
  return [[plist_ copy] autorelease];
}

- (BOOL)isPlistSigned {
  NSMutableDictionary *mutablePlist = [[plist_ mutableCopy] autorelease];
  NSData *signature = [mutablePlist objectForKey:kSignatureKey];
  [mutablePlist removeObjectForKey:kSignatureKey];
  
  NSData *plistData = [NSPropertyListSerialization
                       dataFromPropertyList:mutablePlist
                       format:NSPropertyListXMLFormat_v1_0
                       errorDescription:NULL];
  
  return [signer_ isSignature:signature validForData:plistData];
}

- (BOOL)signPlist {
  if ([self isPlistSigned]) return YES;
  
  NSMutableDictionary *mutablePlist = [[plist_ mutableCopy] autorelease];
  [mutablePlist removeObjectForKey:kSignatureKey];
  
  NSData *plistData = [NSPropertyListSerialization
                       dataFromPropertyList:mutablePlist
                       format:NSPropertyListXMLFormat_v1_0
                       errorDescription:NULL];
  
  NSData *signature = [signer_ signData:plistData];
  BOOL ok = NO;
  
  if (signature != nil) {
    [mutablePlist setObject:signature forKey:kSignatureKey];
    [self setPlist:mutablePlist];
    ok = YES;
  }
  
  return ok;
}

- (BOOL)unsignedPlist {
  if (![self isPlistSigned]) return YES;
  NSMutableDictionary *mutablePlist = [[plist_ mutableCopy] autorelease];
  [mutablePlist removeObjectForKey:kSignatureKey];
  [self setPlist:mutablePlist];
  return YES;
}

@end


@implementation PlistSigner (PrivateMethods)

- (void)setPlist:(NSDictionary *)plist {
  [plist_ autorelease];
  plist_ = [plist copy];
}

@end
