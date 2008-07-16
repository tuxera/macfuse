//
//  KSActionPipe.m
//  Keystone
//
//  Created by Greg Miller on 2/8/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import "KSActionPipe.h"
#import "KSAction.h"


@implementation KSActionPipe

+ (id)pipe {
  return [[[self alloc] init] autorelease];
}

+ (id)pipeWithContents:(id<NSObject>)contents {
  KSActionPipe *pipe = [self pipe];
  [pipe setContents:contents];
  return pipe;
}

- (void)dealloc {
  [contents_ release];
  [super dealloc];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@:%p contents=%@>",
          [self class], self, contents_];
}

- (id)contents {
  return [[contents_ retain] autorelease];
}

- (void)setContents:(id<NSObject>)contents {
  [contents_ autorelease];
  contents_ = [contents retain];
}

- (void)bondFrom:(KSAction *)fromAction to:(KSAction *)toAction {
  [fromAction setOutPipe:self];
  [toAction setInPipe:self];
}

// Ordinarily, class methods are declared at the top of the file, but I think
// this one just makes more sense right next to the equivalent instance method.
+ (void)bondFrom:(KSAction *)fromAction to:(KSAction *)toAction {
  KSActionPipe *pipe = [self pipe];
  [pipe bondFrom:fromAction to:toAction];
}

@end
