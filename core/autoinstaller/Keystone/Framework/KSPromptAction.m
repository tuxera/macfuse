//
//  KSPromptAction.m
//  Keystone
//
//  Created by Greg Miller on 2/13/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import "KSPromptAction.h"
#import "KSKeystone.h"
#import "KSActionProcessor.h"
#import "KSActionPipe.h"
#import "KSUpdateInfo.h"
#import "KSUpdateAction.h"
#import "KSFrameworkStats.h"


@implementation KSPromptAction

// A quick note about stats:
//
// We collect 3 stats in this method.
// kStatPrompts - which is the number of times we send a list of avail updates
// kStatPromptApps - which is the number of apps that we prompted about
// kStatPromptUpdates - which is the number of apps that the user was prompted
//                      for, and the user said "yes" to installing the update
- (NSArray *)productsToUpdateFromAvailable:(NSArray *)availableUpdates {
  int numUpdates = [availableUpdates count];
  if (numUpdates > 0) {
    [[KSFrameworkStats sharedStats] incrementStat:kStatPrompts];
    [[KSFrameworkStats sharedStats] incrementStat:kStatPromptApps
                                               by:numUpdates];
  }
  
  NSArray *updatesToInstall = [[self keystone] action:self
                                 shouldUpdateProducts:availableUpdates];
  
  [[KSFrameworkStats sharedStats] incrementStat:kStatPromptUpdates
                                             by:[updatesToInstall count]];
  
  return updatesToInstall;
}

@end
