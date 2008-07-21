//
//  KSCommandRunner.m
//  Keystone
//
//  Created by Greg Miller on 1/3/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import "KSCommandRunner.h"


// Following Unix conventions, a failure code is any non-zero value
static const int kFailure = 1;


@interface NSTask (KSTaskTimeout)

// Returns YES if the task completed before the |timeout|, NO otherwise. If 
// NO is returned, that means your timeout expired but the task is still
// running. Typically, callers will want to -terminate the task or clean it up
// in some way.
// 
// Args:
//   timeout - the number of seconds to wait for task to complete
//
// Returns:
//   YES if the task completed within the timeout, NO otherwise.
- (BOOL)waitUntilExitWithTimeout:(NSTimeInterval)timeout;

@end


@implementation KSTaskCommandRunner

+ (id)commandRunner {
  return [[[self alloc] init] autorelease];
}

- (int)runCommand:(NSString *)path
         withArgs:(NSArray *)args
      environment:(NSDictionary *)env
           output:(NSString **)output {
  if (path == nil)
    return kFailure;
  
  NSPipe *pipe = [NSPipe pipe];
  NSTask *task = [[[NSTask alloc] init] autorelease];
  [task setLaunchPath:path];
  if (args) [task setArguments:args];
  if (env) [task setEnvironment:env];
  [task setStandardOutput:pipe];
  
  @try {
    // -launch will throw if it can't find |path|
    [task launch];
  }
  @catch (id ex) {
    GTMLoggerInfo(@"Caught exception while trying to launch task for "
                  @"%@, args=%@, env=%@: ex=%@", path, args, env, ex);
    return kFailure;
  }
  
  if (output) {
    NSData *outData = [[pipe fileHandleForReading] readDataToEndOfFile];
    NSString *outString = 
    [[[NSString alloc] initWithData:outData
                           encoding:NSUTF8StringEncoding] autorelease];
    *output = outString;
  }
  
  // Wait up to 1 hour for the task to complete
  BOOL ok = [task waitUntilExitWithTimeout:3600];
  if (!ok) {
    [task terminate];  // COV_NF_LINE
    return kFailure;   // COV_NF_LINE
  }
  
  return [task terminationStatus];
}

@end


@implementation NSTask (KSTaskTimeout)

// Spins the runloop for one second at a time up to a maximum of |timeout|
// seconds, waiting for the task to finish running.
- (BOOL)waitUntilExitWithTimeout:(NSTimeInterval)timeout {
  static const NSTimeInterval step = 1;
  NSTimeInterval waitTime = 0;
  while (waitTime < timeout && [self isRunning]) {
    waitTime += step;
    NSDate *stepSec = [NSDate dateWithTimeIntervalSinceNow:step];
    [[NSRunLoop currentRunLoop] runUntilDate:stepSec];
  }
  return ([self isRunning] == NO);
}

@end


