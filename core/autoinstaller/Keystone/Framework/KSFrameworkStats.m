//
//  KSFrameworkStats.m
//  Keystone
//
//  Created by Greg Miller on 5/1/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import "KSFrameworkStats.h"


static KSStatsCollection *gSharedStats;

@implementation KSFrameworkStats

+ (KSStatsCollection *)sharedStats {
  return gSharedStats;
}

+ (void)setSharedStats:(KSStatsCollection *)stats {
  [gSharedStats autorelease];
  gSharedStats = [stats retain];
}

@end
