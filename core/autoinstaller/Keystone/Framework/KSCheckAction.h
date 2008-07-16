//
//  KSCheckAction.h
//  Keystone
//
//  Created by Greg Miller on 2/15/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KSMultiAction.h"


// KSCheckAction
//
// This KSMultiAction runs one KSUpdateCheckAction for each unique server URL
// found in a ticket. The output of all the sub-KSUpdateCheckActions is
// collected and the aggregate output is set as this action's output (via its
// outPipe).
//
// Sample usage:
//   KSActionProcessor *ap = ...
//   NSArray *tickets = ... tickets that could be for any arbitrary URLs ...
// 
//   KSAction *checker = [KSCheckAction actionWithTickets:tickets];
//   
//   [ap enqueueAction:checker];
//   [ap startProcessing];
//
//   ... spin runloop until done ...
//   NSArray *agg = [[checker outPipe] contents];
//
// That last line will return an array with the aggregate output from all the 
// sub-KSUpdateCheckActions.
//
// A KSCheckAction completes "successfully" if *any* of its
// sub-KSUpdateCheckActions complete successfully. They do not all need to be
// successfull in order for this class to be successful. This handles the case
// where one of the URLs for one of the KSUpdateCheckActions is bad but the 
// rest are fine. In this case, we shouldn't fail the whole operation just from
// one bad URL. But in the case where the user has no internet connetion and 
// ALL the sub-KSUpdateCheckActions fail, we do want to report that this multi-
// action failed.
//
@interface KSCheckAction : KSMultiAction {
 @private
  NSArray *tickets_;
  NSDictionary *params_;
  BOOL wasSuccessful_;
}

// Returns an autoreleased KSCheckAction. See the designated initializer for
// more details.
+ (id)actionWithTickets:(NSArray *)tickets params:(NSDictionary *)params;
+ (id)actionWithTickets:(NSArray *)tickets;

// Designated initializer. Returns a KSCheckAction that will create
// sub-KSUpdateCheckActions for each group of tickets to each unique server URL.
// |tickets| must be an array of KSTicket objects. The tickets do not need to 
// point to the same server URL. A nil or empty array of tickets is allowed;
// this action will just immediately finish running and will return an empty
// output array as if no updates were available.
// If specified, |params| is an NSDictionary indexed by the keys in
// KSKeystoneParameters.h.  These paramaters are passed down to
// objects which may be created by this class.
- (id)initWithTickets:(NSArray *)tickets params:(NSDictionary *)params;
- (id)initWithTickets:(NSArray *)tickets;

@end
