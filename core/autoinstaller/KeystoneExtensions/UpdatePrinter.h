//
//  UpdatePrinter.h
//  autoinstaller
//
//  Created by Greg Miller on 7/16/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


// UpdatePrinter
//
// Prints out an array of product updates (i.e., and array of dictionaries).
// The updates are simply sent a -description message and the output is ent to 
// stdout.
//
@interface UpdatePrinter : NSObject

// Prints the |productUpdates| to stdout.
- (void)printUpdates:(NSArray *)productUpdates;

@end


// PlistUpdatePrinter
// 
// Prints the product updates in a plist format.
//
@interface PlistUpdatePrinter : UpdatePrinter

// No new methods added.

@end
