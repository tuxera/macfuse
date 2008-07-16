//
//  EncryptedPlistServer.m
//  autoinstaller
//
//  Created by Greg Miller on 7/15/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import "EncryptedPlistServer.h"


@implementation EncryptedPlistServer

- (NSArray *)updateInfosForResponse:(NSURLResponse *)response
                               data:(NSData *)data {
  // TODO: decrypt the data. Until then, this class will clearly only work w/
  // unencrypted data objects.
  return [super updateInfosForResponse:response data:data];
}

@end
