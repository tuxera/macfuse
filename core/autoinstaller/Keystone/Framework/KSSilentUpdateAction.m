//
//  KSSilentUpdateAction.m
//  Keystone
//
//  Created by Greg Miller on 2/19/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import "KSSilentUpdateAction.h"
#import "KSKeystone.h"
#import "KSActionProcessor.h"
#import "KSActionPipe.h"
#import "KSUpdateInfo.h"
#import "KSUpdateAction.h"


@implementation KSSilentUpdateAction

- (NSArray *)productsToUpdateFromAvailable:(NSArray *)availableUpdates {
  return [[self keystone] action:self
    shouldSilentlyUpdateProducts:availableUpdates];
}

@end

