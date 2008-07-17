//
//  UpdatePrinter.m
//  autoinstaller
//
//  Created by Greg Miller on 7/16/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import "UpdatePrinter.h"


@implementation UpdatePrinter

- (void)printUpdates:(NSArray *)productUpdates {
  printf("Available updates: %s\n", [[productUpdates description] UTF8String]);
}

@end


@implementation PlistUpdatePrinter

- (void)printUpdates:(NSArray *)productUpdates {
  NSDictionary *update = nil;
  NSEnumerator *updateEnumerator = [productUpdates objectEnumerator];
  while ((update = [updateEnumerator nextObject])) {
    // First, remove the keys that were "derived" from the main keys and added
    // to this update by Keystone itself. We need to remove these because they 
    // may not be plist types.
    NSMutableDictionary *mutableUpdate = [[update mutableCopy] autorelease];
    NSArray *keys = [mutableUpdate allKeys];
    NSArray *derivedKeys = [keys filteredArrayUsingPredicate:
                            [NSPredicate predicateWithFormat:
                             @"SELF beginswith 'kServer'"]];
    [mutableUpdate removeObjectsForKeys:derivedKeys];
    
    // Now, print the dictionary, which should now be a valid plist
    NSData *data = [NSPropertyListSerialization
                    dataFromPropertyList:mutableUpdate
                                  format:NSPropertyListXMLFormat_v1_0
                        errorDescription:NULL];
    NSString *plist = [[[NSString alloc]
                        initWithData:data
                            encoding:NSUTF8StringEncoding] autorelease];
    printf("%s", [plist UTF8String]);
  }
}

@end
