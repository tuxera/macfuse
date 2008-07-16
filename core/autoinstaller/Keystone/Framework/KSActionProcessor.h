//
//  KSActionProcessor.h
//  Keystone
//
//  Created by Greg Miller on 1/9/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KSAction;

// KSActionProcessor
//
// This class encapsulates a queue of KSAction instances, and manages the
// execution of the actions. The KSActionProcessor will run one KSAction at a
// time. Each KSAction itself may run asynchronously (or synchronously), and
// must message the KSActionProcessor when it is finished (see the
// KSActionProcessorCallbacks informal protocol below).  KSAction instances are
// dequeued and run in FIFO order. KSActions may also create new KSActions and
// add them to the KSActionProcessor queue. Once started, the KSActionProcessor
// will not stop processing actions until the queue is empty (or until the
// -stopProcessing message is sent). This includes processing all the actions
// that are added while the action queue is being processed.
//
// KSActions may only be in one KSActionProcessor at a time. When a KSAction is
// added to a KSActionProcessor, the processor then "owns" that KSAction.
//
// Sample usage
// ------------
//   KSAction *action = ... create a concrete KSAction instance ...
//   KSActionProcessor *ap = [[KSActionProcessor alloc] init];
//   [ap enqueueAction:action];
//   [ap startProcessing];  
// 
// This code creates a KSActionProcessor instance, enqueues an action, and
// starts the KSActionProcessor processing. Once this happens, the
// KSActionProcessor will start dequeuing actions and running them one by one.
// If the added action adds a new action to the KSActionProcessor's queue, that
// action will be processed as well. The KSActionProcessor will keep processing 
// the queue until it's empty (or until it receives a -stopProcessing) message.
// Again, KSActions are always run one at a time--even asynchronous ones.
//
// Though not required, KSActionProcessors can be given a delegate when they're
// created. The delegate is sent informational messages as actions get
// processed. See the KSActionProcessorDelegate informal protocol below for more
// details.
@interface KSActionProcessor : NSObject {
 @private
  NSMutableArray *actionQ_;
  BOOL isProcessing_;
  KSAction *currentAction_;
  id delegate_;  // weak
  int actionsCompleted_;
}

// Returns a KSActionProcessor that will use the specified object as a delegate.
// A nil delegate is valid, and is used when -init is used to initialize
// the instance.
- (id)initWithDelegate:(id)delegate;

// Returns the delegate.
- (id)delegate;

// Sets the delegate. The delegate is allowed to be nil.
- (void)setDelegate:(id)delegate;

// Adds the specified action to the end of the action queue.
- (void)enqueueAction:(KSAction *)action;

// Returns the array of actions in the action queue.
- (NSArray *)actions;

// Tells the KSActionProcessor to start dequeuing and processing the KSActions
// in the action queue. If the queue is empty, this method does nothing. If 
// there are actions to be processed, -isProcessing will be true.
//
// If a delegate was specified, the delegate will be sent
// -processor:startingAction: message for each action that is started.
- (void)startProcessing;

// Tells the KSActionProcessor to stop processing actions. If an action is
// currently being processed, it will be sent a -terminateAction message. 
- (void)stopProcessing;

// Returns YES if the KSActionProcessor is currently processing actions, and 
// NO otherwise.
- (BOOL)isProcessing;

// Returns the KSAction that is currently being processed.
- (KSAction *)currentAction;

// Returns the total number of actions we have ever completed processing on.
// Helpful for unit testing.
- (int)actionsCompleted;

@end


// KSActionProcessorCallbacks
//
// Callback methods that KSAction instances can call on the KSActionProcessor
// that is running them. 
@interface KSActionProcessor (KSActionProcessorCallbacks)

// KSAction classes MUST send this message when they are done running. This is
// the only way that the KSActionProcessor will know that the action is done.
// |wasOK| should indicate whether or not the action finished successfully.
- (void)finishedProcessing:(KSAction *)action successfully:(BOOL)wasOK;

@end


// KSActionProcessorDelegate
//
// Methods that a KSActionProcessor's delegate can optionally implement. None of
// these methods are required, and the delegate itself is totally optional.
// These methods are purely for informational purposes only.
@interface NSObject (KSActionProcessorDelegate)

// Sent when the KSActionProcessor starts processing the action queue.
- (void)processingStarted:(KSActionProcessor *)processor;

// Sent when the action queue is emptied.
- (void)processingDone:(KSActionProcessor *)processor;

// Sent when processing has stopped. The receipt of this message does not imply
// that the queue has been emptied, just that processing has stopped. The
// processingDone: message will be sent when the queue has been emptied.
- (void)processingStopped:(KSActionProcessor *)processor;

// Called after an action has been added to the action queue.
- (void)processor:(KSActionProcessor *)processor
   enqueuedAction:(KSAction *)action;

// Called right before the KSActionProcessor starts a KSAction by sending it
// the -performAction message.
- (void)processor:(KSActionProcessor *)processor
   startingAction:(KSAction *)action;

// Called once the KSAction informs the KSActionProcessor that the action has 
// finished. |wasOK| indicates whether or not the action finished successfully.
- (void)processor:(KSActionProcessor *)processor
   finishedAction:(KSAction *)action
     successfully:(BOOL)wasOK;

@end
