//
//  KSUUID.h
//  Keystone Common
//
//  Created by dmaclach on 3/14/07.
//  Moved to Keystone Common and trimmed down by mdalrymple 7/11/08
//  Copyright 2008 Google Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

// A class to generate universally uniquie UUID identifier strings.
// To use:
//    NSString *uuid = [KSUUID uuidString];
//
// This will give you a UUID string of the format:
//   XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
//
@interface KSUUID : NSObject

+ (NSString *)uuidString;

@end
