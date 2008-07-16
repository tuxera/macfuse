//
//  KSFetcherFactory.h
//
//  Created by John Grabowski on 1/4/08
//  Copyright 2008 Google Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GTMHTTPFetcher;

// A factory class that creates GTMHTTPFetcher objects.  We pass this
// to a KSUpdateChecker.  Since a KSUpdateChecker may need more than
// one GTMHTTPFetcher (depending on the KSServer implementation), we
// must pass in a factory instead of just a GTMHTTPFetcher.
@interface KSFetcherFactory : NSObject

// Returns an autoreleased instance of KSFetcherFactory
+ (KSFetcherFactory *)factory;

// Returns an autoreleased object compatible with GTMHTTPFetcher,
// initialized with the given NSURLRequest.
- (GTMHTTPFetcher *)createFetcherForRequest:(NSURLRequest *)request;

@end
