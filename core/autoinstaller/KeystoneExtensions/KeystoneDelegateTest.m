//
//  KeystoneDelegateTest.m
//  autoinstaller
//
//  Created by Greg Miller on 7/19/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "KeystoneDelegate.h"
#import "UpdatePrinter.h"


@interface KeystoneDelegateTest : SenTestCase
@end

@implementation KeystoneDelegateTest

- (void)testCreation {
  KeystoneDelegate *delegate = [[[KeystoneDelegate alloc] init] autorelease];
  STAssertNotNil(delegate, nil);
  
  delegate = [[[KeystoneDelegate alloc] initWithPrinter:nil
                                              doInstall:NO] autorelease];
  STAssertNotNil(delegate, nil);
  
  UpdatePrinter *printer = [UpdatePrinter printer];
  delegate = [[[KeystoneDelegate alloc] initWithPrinter:printer
                                              doInstall:NO] autorelease];
  STAssertNotNil(delegate, nil);
}

@end
