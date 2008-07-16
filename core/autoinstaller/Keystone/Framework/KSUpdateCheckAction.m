//
//  KSUpdateCheckAction.m
//
//  Created by John Grabowski on 1/30/08
//  Copyright 2008 Google Inc. All rights reserved.
//

#import "KSUpdateCheckAction.h"
#import "GTMHTTPFetcher.h"
#import "KSFetcherFactory.h"
#import "KSServer.h"
#import "KSTicket.h"
#import "KSActionProcessor.h"
#import "KSActionPipe.h"
#import "KSUpdateAction.h"


@interface KSUpdateCheckAction (FetcherCallbacks)	
	
// A KSUpdateCheckAction may ask for information via GTMHTTPFetcher	
// which is async.  These are callbacks passed to [GTMHTTPFetcher	
// beginFetchingWithDelegate::::] to let us know what happened.	
- (void)fetcher:(GTMHTTPFetcher *)fetcher finishedWithData:(NSData *)data;	
- (void)fetcher:(GTMHTTPFetcher *)fetcher failedWithError:(NSError *)error;	
	
@end


@implementation KSUpdateCheckAction

+ (id)checkerWithServer:(KSServer *)server tickets:(NSArray *)tickets {
  return [[[KSUpdateCheckAction alloc] initWithServer:server
                                              tickets:tickets] autorelease];
}

- (id)init {
  return [self initWithServer:nil tickets:nil];
}

- (id)initWithServer:(KSServer *)server tickets:(NSArray *)tickets {
  return [self initWithFetcherFactory:[KSFetcherFactory factory]
                               server:server
                              tickets:tickets];
}

- (id)initWithFetcherFactory:(KSFetcherFactory *)fetcherFactory
                      server:(KSServer *)server
                     tickets:(NSArray *)tickets {
  if ((self = [super init])) {
    if ((fetcherFactory == nil) ||
        (server == nil) ||
        ([tickets count] == 0)) {
      [self release];
      return nil;
    }
    // check invariant; make sure all tickets point to the same server URL
    if ([tickets count] > 1) {
      KSTicket *first = [tickets objectAtIndex:0];
      NSEnumerator *tenum = [tickets objectEnumerator];
      KSTicket *t = nil;
      while ((t = [tenum nextObject])) {
        if (![[first serverURL] isEqual:[t serverURL]]) {
          GMLoggerInfo(@"UpdateChecker passed tickets with different URLs?");
          [self release];
          return nil;
        }
      }
    }
    fetcherFactory_ = [fetcherFactory retain];
    server_ = [server retain];
    tickets_ = [tickets copy];
    fetchers_ = [[NSMutableArray alloc] init];
    allSuccessful_ = YES;  // so far...
  }
  return self;
}

- (void)dealloc {
  [fetcherFactory_ release];
  [server_ release];
  [tickets_ release];
  [fetchers_ release];
  delegate_ = nil;
  [super dealloc];
}

// Override of -[KSAction performAction] to define ourselves as an
// action object.  Like KSAction, we are called from our owning
// KSActionProcessor.  This method happens to be async.
- (void)performAction {
  NSArray *requests = [server_ requestsForTickets:tickets_];

  // Try and make debugging easier
  NSEnumerator *renum = [requests objectEnumerator];
  NSURLRequest *req = nil;
  
#ifdef DEBUG
  int x = 0;
  while ((req = [renum nextObject])) {
    NSData *data = [req HTTPBody];
    // %.*s since we need length (data not NULL-terminated)
    GMLoggerDebug(@"** XML request %d:\n%.*s", x++,
                  [data length], (char*)[data bytes]);
  }
#endif

  renum = [requests objectEnumerator];
  req = nil;
  while ((req = [renum nextObject])) {
    GTMHTTPFetcher *fetcher = [fetcherFactory_ createFetcherForRequest:req];
    _GTMDevAssert(fetcher, @"no fetcher");
    [fetchers_ addObject:fetcher];
    [fetcher beginFetchWithDelegate:self
                  didFinishSelector:@selector(fetcher:finishedWithData:)
                    didFailSelector:@selector(fetcher:failedWithError:)];
  }
}

- (void)terminateAction {
  NSEnumerator *fenum = [fetchers_ objectEnumerator];
  GTMHTTPFetcher *fetcher = nil;
  while ((fetcher = [fenum nextObject])) {
    if ([fetcher isFetching]) {
      [fetcher stopFetching];
    }
  }
  [fetchers_ removeAllObjects];
}

- (void)requestFinishedForFetcher:(GTMHTTPFetcher *)fetcher success:(BOOL)successful {
  [fetchers_ removeObject:fetcher];
  if (successful == NO)
    allSuccessful_ = NO;
  if ([fetchers_ count] == 0) {
    [[self processor] finishedProcessing:self successfully:allSuccessful_];
  }
}

- (int)outstandingRequests {
  return [fetchers_ count];
}

- (void)setDelegate:(id<KSUpdateCheckActionDelegateProtocol>)delegate {
  delegate_ = delegate;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@:%p server=%@ tickets=%@>",
          [self class], self, server_, tickets_];
}

@end  // KSUpdateCheckAction


@implementation KSUpdateCheckAction (FetcherCallbacks)

- (void)fetcher:(GTMHTTPFetcher *)fetcher finishedWithData:(NSData *)data {
  NSURLResponse *response = [fetcher response];
  NSString *prettyData = [server_ prettyPrintResponse:response data:data];
  GMLoggerDebug(@"** XML response:\n%@", prettyData);
  
  NSArray *results = [server_ updateInfosForResponse:response data:data];
  [[self outPipe] setContents:results];

  [self requestFinishedForFetcher:fetcher success:YES];
}

- (void)fetcher:(GTMHTTPFetcher *)fetcher failedWithError:(NSError *)error {
  GMLoggerError(@"KSUpdateCheckAction failed with error %@", error);
  [delegate_ fetcher:fetcher failedWithError:error];
  [self requestFinishedForFetcher:fetcher success:NO];
}

@end
