//
//  KeystoneDelegate.m
//  autoinstaller
//
//  Created by Greg Miller on 7/10/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import "KeystoneDelegate.h"
#import "KSCommandRunner.h"
#import "KSKeystone.h"
#import "UpdatePrinter.h"


@implementation KeystoneDelegate

- (id)init {
  return [self initWithPrinter:nil doInstall:NO];
}

- (id)initWithPrinter:(UpdatePrinter *)printer doInstall:(BOOL)doInstall {
  if ((self = [super init])) {
    printer_ = [printer retain];
    doInstall_ = doInstall;

    wasSuccess_ = YES;
  }
  return self;
}

- (void)dealloc {
  [printer_ release];
  [super dealloc];
}

- (BOOL)wasSuccess {
  return wasSuccess_;
}

- (NSArray *)keystone:(KSKeystone *)keystone
shouldPrefetchProducts:(NSArray *)products {
  
  [printer_ printUpdates:products];
  
  if (!doInstall_) {
    [keystone stopAndReset];
    return nil;
  }
  
  return products;
}

- (void)keystone:(KSKeystone *)keystone
        finished:(KSUpdateInfo *)updateInfo
      wasSuccess:(BOOL)wasSuccess
     wantsReboot:(BOOL)wantsReboot {
  if (!wasSuccess)
    wasSuccess_ = NO;
}

- (void)keystoneFinished:(KSKeystone *)keystone wasSuccess:(BOOL)wasSuccess {
  if (!wasSuccess)
    wasSuccess_ = NO;
}

- (id<KSCommandRunner>)commandRunnerForKeystone:(KSKeystone *)keystone {
  return [KSTaskCommandRunner commandRunner];
}

@end

