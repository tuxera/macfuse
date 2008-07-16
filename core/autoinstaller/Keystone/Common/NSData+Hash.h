//
//  NSData+Hash.h
//
//  Created by Alex Harper on 4/12/07.
//  Migrated to Keystone by Mark Dalrymple 7/7/08
//  Copyright 2008 Google Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

// A category on NSData that calculates an SHA1 hash based on the data's
// contents.
//
// To use:
//    NSData *dataToBeHashed = [blah contentsAsData];
//    NSData *hash = [dataToBeHashed SHA1Hash];
//
//    If you want to display it in a human-readable format, use GTMBase64:
//    NSString *hashString = [GTMBase64 stringByEncodingData:hash];
//
@interface NSData (KSDataHashAdditions)

// Generate an SHA-1 hash for the supplied data.
//
//  Returns:
//    Autoreleased NSData of the hash (for string version of the hash
//    consider using GTMBase64)
//
- (NSData *)SHA1Hash;

@end
