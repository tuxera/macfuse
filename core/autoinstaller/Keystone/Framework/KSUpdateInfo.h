//
//  KSUpdateInfo.h
//  Keystone
//
//  Created by Greg Miller on 2/18/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


// Dictionary keys for the KSUpdateInfo dictionaries. Although any
// key/value may be included in a results dictionary, the key listed
// here are required unless specified otherwise.
#define kServerProductID     @"kServerProductID"      // NSString
#define kServerCodebaseURL   @"kServerCodebaseURL"    // NSURL
#define kServerCodeSize      @"kServerCodeSize"       // NSNumber
#define kServerCodeHash      @"kServerCodeHash"       // NSString

// These are optional:
#define kServerMoreInfoURLString  @"kServerMoreInfoURLString"   // NSString
#define kServerPromptUser         @"kServerPromptUser"      // BOOL as NSNumber
#define kServerRequireReboot      @"kServerRequireReboot"   // BOOL as NSNumber
#define kServerDisplayVersion     @"kServerDisplayVersion"  // NSString
#define kServerLocalizationBundle \
  @"kServerLocalizationBundle"  // NSString, either a path or a bundleID

// KSUpdateInfo
//
// This object encapsulates a server-independent response containing
// information about a product update. Objects of this type are
// returned from KSServer instances via their -updateInfosForResponse:data: 
// method.
//
// Implementation note
// ===================
// The abstraction here is the "KSUpdateInfo". It is currently
// implemented as an NSDictionary to allow arbitrary keys to be
// added. In the future we may change this to be a full blown class
// rather than a typedef, but for now, just the abstraction (i.e., the
// typedef) is sufficient.
//
// Note that if you are using NSPredicate to filter an array of KSUpdateInfos,
// you'll want to use the dictionary keys (e.g. kServerRequireReboot) instead
// of the wrapper api (-requireReboot)
//
// (Using a typedef here instead breaks DO on tiger.  The type gets @encoded
// as a pointer to an NSDictionary rather than an NSDictionary object, which
// really confuses things.  Leopard has the same encoding issue, but handles
// it more gracefully on the remote side.)
#define KSUpdateInfo NSDictionary
@interface NSDictionary (KSUpdateInfoMethods)

// Returns the object for kServerProductID
- (NSString *)productID;

// Returns the object for kServerCodebaseURL
- (NSURL *)codebaseURL;

// Returns the object for kServerCodeSize
- (NSNumber *)codeSize;

// Returns the object for kServerCodeHash
- (NSString *)codeHash;

// Returns the object for kServerMoreInfoURLString.
// The string may include the substring '${hl}, which should be
// replaced with the langauge code of the currently running
// localization.
- (NSString *)moreInfoURLString;

// Returns the object for kServerPromptUser
- (NSNumber *)promptUser;

// Returns the object for kServerRequireReboot
- (NSNumber *)requireReboot;

// Returns the object for kServerLocalizationBundle
- (NSString *)localizationBundle;

// Returns the object for kServerDisplayVersion
- (NSString *)displayVersion;

@end


