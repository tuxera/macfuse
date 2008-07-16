//
//  KSUpdateInfo.m
//  Keystone
//
//  Created by Greg Miller on 2/18/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import "KSUpdateInfo.h"


@implementation NSDictionary (KSUpdateInfoMethods)

- (NSString *)productID {
  return [self objectForKey:kServerProductID];
}

- (NSURL *)codebaseURL {
  return [self objectForKey:kServerCodebaseURL];
}

- (NSNumber *)codeSize {
  return [self objectForKey:kServerCodeSize];
}

- (NSString *)codeHash {
  return [self objectForKey:kServerCodeHash];
}

- (NSString *)moreInfoURLString {
  return [self objectForKey:kServerMoreInfoURLString];
}

- (NSNumber *)promptUser {
  return [self objectForKey:kServerPromptUser];
}

- (NSNumber *)requireReboot {
  return [self objectForKey:kServerRequireReboot];
}

- (NSString *)localizationBundle {
  return [self objectForKey:kServerLocalizationBundle];
}

- (NSString *)displayVersion {
  return [self objectForKey:kServerDisplayVersion];
}

@end
