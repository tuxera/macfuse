//
//  KSFetcherFactory.m
//
//  Created by John Grabowski on 1/4/08
//  Copyright 2008 Google Inc. All rights reserved.
//

#import "KSFetcherFactory.h"
#import "GTMHTTPFetcher.h"


@implementation KSFetcherFactory

+ (KSFetcherFactory *)factory {
  return [[[self alloc] init] autorelease];
}

- (GTMHTTPFetcher *)createFetcherForRequest:(NSURLRequest *)request {
  return [GTMHTTPFetcher httpFetcherWithRequest:request];
}

@end
