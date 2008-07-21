//
//  KSAction.m
//  Keystone
//
//  Created by Greg Miller on 1/9/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import "KSAction.h"
#import "KSActionProcessor.h"
#import "KSActionPipe.h"
#import "GTMLogger.h"


@implementation KSAction

- (id)init {
  if ((self = [super init])) {
    [self setInPipe:nil];
    [self setOutPipe:nil];
  }
  return self;
}

- (void)dealloc {
  [processor_ release];
  [inpipe_ release];
  [outpipe_ release];
  [super dealloc];
}

- (KSActionProcessor *)processor {
  return [[processor_ retain] autorelease];
}

- (void)setProcessor:(KSActionProcessor *)processor {
  [processor_ autorelease];
  processor_ = [processor retain];
}

- (KSActionPipe *)inPipe {
  return [[inpipe_ retain] autorelease];
}

- (void)setInPipe:(KSActionPipe *)inpipe {
  [inpipe_ autorelease];
  inpipe_ = [inpipe retain];
  if (inpipe_ == nil)  // Never let inpipe be nil
    inpipe_ = [[KSActionPipe alloc] init];
}

- (KSActionPipe *)outPipe {
  return [[outpipe_ retain] autorelease];
}

- (void)setOutPipe:(KSActionPipe *)outpipe {
  [outpipe_ autorelease];
  outpipe_ = [outpipe retain];
  if (outpipe_ == nil)  // Never let outpipe be nil
    outpipe_ = [[KSActionPipe alloc] init];
}

- (BOOL)isRunning {
  return [[self processor] currentAction] == self;
}

// COV_NF_START
- (void)performAction {
  // Subclasses must override this method, otherwise their actions will be
  // useless.

  // If this method is not overridden, we'll _GTMDevAssert so that debug builds
  // break, but in Release builds we'll just log and tell the processor that
  // we're done so it doesn't hang.
  
  _GTMDevAssert(NO, @"-performAction: method not overridden");
  [processor_ finishedProcessing:self successfully:NO];
}
// COV_NF_END

- (void)terminateAction {
  // Do nothing. Subclasses may optionally override this method if they need to
  // do special cleanup when their action is being terminated.
}

@end
