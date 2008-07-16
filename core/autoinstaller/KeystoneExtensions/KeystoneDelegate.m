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


@implementation KeystoneDelegate

- (id)init {
  return [self initWithList:YES install:NO];
}

- (id)initWithList:(BOOL)list install:(BOOL)install {
  if ((self = [super init])) {
    list_ = list;
    install_ = install;
    wasSuccess_ = YES;
  }
  return self;
}

- (BOOL)wasSuccess {
  return wasSuccess_;
}

- (NSArray *)keystone:(KSKeystone *)keystone
shouldPrefetchProducts:(NSArray *)products {
  if (list_) {
    if ([products count] == 0) {
      printf("No updates available.\n");
    } else {
      printf("Available updates: %s\n", [[products description] UTF8String]);
    }
    [keystone stopAndReset];
    return nil;
  } else if (install_) {
    return products;
  }
  
  return nil;
}

- (NSArray *)keystone:(KSKeystone *)keystone
 shouldUpdateProducts:(NSArray *)products {
  if (install_) {
    return products;
  }
  
  return nil;
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

