//
//  KSKeystoneBroker.m
//  Keystone
//
//  Created by Greg Miller on 3/18/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import "KSKeystoneBroker.h"
#import "KSKeystone.h"


@implementation KSKeystoneBroker

+ (id)brokerWithKeystone:(KSKeystone *)keystone {
  return [[[self alloc] initWithKeystone:keystone] autorelease];
}

- (id)init {
  return [self initWithKeystone:nil];
}

- (id)initWithKeystone:(KSKeystone *)keystone {
  if ((self = [super init])) {
    keystone_ = [keystone retain];
    lock_ = [[NSLock alloc] init];
    if (keystone_ == nil || lock_ == nil) {
      [self release];
      return nil;
    }
  }
  return self;
}

- (void)dealloc {
  [self forceUnlock];
  [keystone_ release];
  [lock_ release];
  [super dealloc];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@:%p keystone=%@ lock=%@>",
          [self class], self, keystone_, lock_];
}

- (KSKeystone *)claimKeystone {
  return [lock_ tryLock] ? keystone_ : nil;
}

- (void)returnKeystone:(KSKeystone *)keystone {
  if (keystone != nil)
    [lock_ unlock];
}

- (void)forceUnlock {
  // Stop and reset the KSKeystone instance, and make sure the lock is unlocked
  [keystone_ setDelegate:nil];
  [keystone_ stopAndReset];
  [lock_ tryLock];
  [lock_ unlock];
  
  GTMLoggerInfo(@"force unlocked: %@", lock_);
}

@end
