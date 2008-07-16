//
//  NSData+Hash.m
//
//  Created by Alex Harper on 4/12/07.
//  Migrated to Keystone by Mark Dalrymple 7/7/08
//  Copyright 2008 Google Inc. All rights reserved.
//

#import "NSData+Hash.h"

#import <CommonCrypto/CommonDigest.h>

@implementation NSData (KSDataHashAdditions)

- (NSData *)SHA1Hash {
  CC_SHA1_CTX sha1Context;
  unsigned char hash[CC_SHA1_DIGEST_LENGTH];
  
  CC_SHA1_Init(&sha1Context);
  CC_SHA1_Update(&sha1Context, [self bytes], [self length]);
  CC_SHA1_Final(hash, &sha1Context);
  
  return [NSData dataWithBytes:hash length:sizeof(hash)];
}

@end
