//
//  KSExistenceChecker.h
//  Keystone
//
//  Created by Greg Miller on 12/10/07.
//  Copyright 2007 Google Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

// An abstract class that encapsulates the ability to check for the existence
// of something. Concrete subclasses may provide the ability to check existence
// by stating a path, asking LaunchServices whether an application with a
// specific bundle ID exists, or running a Spotlight query. 
@interface KSExistenceChecker : NSObject <NSCoding>

// Returns an existence checker whose -exists method always returns NO. Useful 
// for testing.
+ (id)falseChecker;

// Subclasses must override this method. It should return YES if the represented
// object exists, NO otherwise.
- (BOOL)exists;

@end


//
// Concrete subclasses 
//


// Existence checker for checking the existence of a path.
@interface KSPathExistenceChecker : KSExistenceChecker {
 @private
  NSString *path_;
}

// Returns an existence checker that will check the existence of |path|.
+ (id)checkerWithPath:(NSString *)path;
- (id)initWithPath:(NSString *)path;

@end


// Existence checker for querying LaunchServices about the existence of an
// application with the specified bundle ID.
@interface KSLaunchServicesExistenceChecker : KSExistenceChecker {
 @private
  NSString *bundleID_;
}

// Returns an existence checker that will check for the existence of |bid| in 
// the LaunchServices database.
+ (id)checkerWithBundleID:(NSString *)bid;
- (id)initWithBundleID:(NSString *)bid;

@end


// Existence checker that queries Spotlight. If Spotlight returns any results, 
// the existence check will be YES, if Spotlight doesn't find anything, the
// existence check will be NO. It does not matter /what/ is found, just that 
// something is found.
@interface KSSpotlightExistenceChecker : KSExistenceChecker {
 @private
  NSString *query_;
}

// Returns an existence checker that will use Spotlight to see if |query| 
// returns any results.
+ (id)checkerWithQuery:(NSString *)query;
- (id)initWithQuery:(NSString *)query;

@end
