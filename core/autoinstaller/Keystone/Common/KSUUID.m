//
//  KSUUID.m
//  Keystone
//
//  Created by dmaclach on 3/14/07.
//  Moved to Keystone Common and trimmed down by mdalrymple 7/11/08
//  Copyright 2008 Google Inc. All rights reserved.
//

#import "KSUUID.h"

#import <uuid/uuid.h>

@implementation KSUUID

+ (NSString *)uuidString {
  uuid_t uuid;
  uuid_generate(uuid);
  char buffer[37] = { 0 };
  uuid_unparse_upper(uuid, buffer);

  return [NSString stringWithUTF8String:buffer];
}

@end
