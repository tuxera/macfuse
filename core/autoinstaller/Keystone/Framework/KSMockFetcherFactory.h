//
//  KSMockFetcherFactory.h
//
//  Created by John Grabowski on 1/08/08
//  Copyright 2008 Google Inc. All rights reserved.
//
// Mock fetcher factories for testing.

#import "KSFetcherFactory.h"
#import "GTMHTTPFetcher.h"

// A fetcher factory is needed for the UpdateChecker API.
// This lets us provide mock factories with special behaviors.
@interface KSMockFetcherFactory : KSFetcherFactory {
 @private
  // The actual class of the fetcher created by this factory.  This
  // class (and args to construct it) are implicitly determined by the
  // class method used to create a KSMockFetcherFactory.  For example,
  // +alwaysFinishWithData sets class_ to be
  // KSMockFetcherFinishWithData, a fetcher which does just what it
  // says.
  Class class_;
  id arg1_;
  id arg2_;
  int status_;
}

+ (KSMockFetcherFactory *)alwaysFinishWithData:(NSData *)data;
+ (KSMockFetcherFactory *)alwaysFailWithError:(NSError *)error;

@end

