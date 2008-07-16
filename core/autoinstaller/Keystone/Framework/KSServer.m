//
//  KSServer.m
//  KeystoneServer
//
//  Created by Greg Miller on 12/18/07.
//  Copyright 2007 Google Inc. All rights reserved.
//

#import "KSServer.h"


@implementation KSServer

- (id)init {
  return [self initWithURL:nil];
}

- (id)initWithURL:(NSURL *)url {
  if ((self = [super init])) {
    if (url == nil) {
      [self release];
      return nil;
    }
    url_ = [url retain];
  }
  return self;
}

- (void)dealloc {
  [url_ release];
  [super dealloc];
}

- (NSURL *)url {
  return url_;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@:%p url=%@>",
          [self class], self, url_];
}


//
// "Abstract" methods.
//


// Subclasses to override.
- (NSArray *)requestsForTickets:(NSArray *)tickets {
  return nil;
}

// Subclasses to override.
- (NSArray *)updateInfosForResponse:(NSURLResponse *)response data:(NSData *)data {
  return nil;
}

- (NSString *)prettyPrintResponse:(NSURLResponse *)response data:(NSData *)data {
  return nil;
}

@end
