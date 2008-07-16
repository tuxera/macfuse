//
//  KSCheckAction.m
//  Keystone
//
//  Created by Greg Miller on 2/15/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import "KSCheckAction.h"
#import "KSTicket.h"
#import "KSUpdateCheckAction.h"
#import "EncryptedPlistServer.h"
#import "KSActionPipe.h"
#import "KSActionProcessor.h"
#import "KSTicketStore.h"
#import "KSFrameworkStats.h"


@implementation KSCheckAction

+ (id)actionWithTickets:(NSArray *)tickets params:(NSDictionary *)params {
  return [[[self alloc] initWithTickets:tickets params:params] autorelease];
}

+ (id)actionWithTickets:(NSArray *)tickets {
  return [[[self alloc] initWithTickets:tickets] autorelease];
}

- (id)initWithTickets:(NSArray *)tickets params:(NSDictionary *)params {
  if ((self = [super init])) {
    tickets_ = [tickets copy];
    params_ = [params retain];
  }
  return self;
}

- (id)initWithTickets:(NSArray *)tickets {
  return [self initWithTickets:tickets params:nil];
}

- (void)dealloc {
  [params_ release];
  [tickets_ release];
  [super dealloc];
}

- (void)performAction {
  NSDictionary *tixMap = [tickets_ ticketsByURL];
  if (tixMap == nil) {
    GMLoggerInfo(@"no tickets to check on.");
    [[self outPipe] setContents:nil];
    [[self processor] finishedProcessing:self successfully:YES];
    return;
  }
  
  NSURL *url = nil;
  NSEnumerator *tixMapEnumerator = [tixMap keyEnumerator];
  
  while ((url = [tixMapEnumerator nextObject])) {
    NSArray *tickets = [tixMap objectForKey:url];
    [[KSFrameworkStats sharedStats] incrementStat:kStatTickets
                                               by:[tickets count]];
    
    // We don't want to check for products that are currently not installed, so 
    // we need to filter the array of tickets to only those ticktes whose 
    // existence checker indicates that they are currently installed.
    // NSPredicate makes this very easy.
    NSArray *filteredTickets =
      [tickets filteredArrayUsingPredicate:
       [NSPredicate predicateWithFormat:@"existenceChecker.exists == YES"]];
    
    if ([filteredTickets count] == 0)
      continue;
    
    GMLoggerInfo(@"filteredTickets = %@", filteredTickets);
    [[KSFrameworkStats sharedStats] incrementStat:kStatValidTickets
                                               by:[filteredTickets count]];
    
    KSServer *server = [EncryptedPlistServer serverWithURL:url];
    KSAction *checker = [KSUpdateCheckAction checkerWithServer:server
                                                       tickets:filteredTickets];
    [[self subProcessor] enqueueAction:checker];
  }

  if ([[[self subProcessor] actions] count] == 0) {
    GMLoggerInfo(@"No checkers created.");
    [[self processor] finishedProcessing:self successfully:YES];
    return;
  }
  
  // Our output needs to be the aggregate of all our sub-action checkers' output
  // For now, we'll just set our output to a mutable array, that we'll append to
  // as each sub-action checker finishs.
  [[self outPipe] setContents:[NSMutableArray array]];
  
  [[self subProcessor] startProcessing];
}

// KSActionProcessor callback method that will be called by our subProcessor
- (void)processor:(KSActionProcessor *)processor
   finishedAction:(KSAction *)action
     successfully:(BOOL)wasOK {
  [[KSFrameworkStats sharedStats] incrementStat:kStatChecks];
  if (wasOK) {
    // Get the checker's output contents and append it to our own output.
    NSArray *checkerOutput = [[action outPipe] contents];
    [[[self outPipe] contents] addObjectsFromArray:checkerOutput];
    // See header comments about why this gets set to YES here.
    wasSuccessful_ = YES;
  } else {
    [[KSFrameworkStats sharedStats] incrementStat:kStatFailedChecks];
  }
}

// Overridden from KSMultiAction. Called by our subProcessor when it finishes.
// We tell our parent processor that we succeeded if *any* of our subactions
// succeeded.
- (void)processingDone:(KSActionProcessor *)processor {
  [[self processor] finishedProcessing:self successfully:wasSuccessful_];
}

@end
