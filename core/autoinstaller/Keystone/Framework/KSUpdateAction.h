//
//  KSUpdateAction.h
//  Keystone
//
//  Created by Greg Miller on 1/29/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import "KSAction.h"
#import "KSCompositeAction.h"
#import "KSUpdateInfo.h"

@protocol KSCommandRunner;

// KSUpdateAction (KSDownloadAction + KSInstallAction)
//
// A KSUpdateAction is a composite action that is made up of a KSDownloadAction
// and a KSInstallAction. See the KSCompositeAction class for more details about
// composite actions in general. The download will run first, and if it is
// successful, the install action will run to install what was just downloaded.
// If either of these sub-actions fail, the KSUpdateAction itself will fail.
// Upon completion, the KSUpdateAction's outPipe will contain the outPipe
// contents from the KSInstallAction, which is the return value of the installer
// boxed as an NSNumber.
//
// Sample code:
//
///  KSActionProcessor *ap = ... get or create a KSActionProcessor ...
//
//   KSUpdateInfo *info = ... get KSUpdateInfo object ...
//   id<KSCommandRunner> runner = ... a KSCommandRunner ...
//   BOOL ui = ... a BOOL indicating whether the user initiated this update ...
//
//   KSAction *action = nil;
//     action = [KSUpdateAction actionWithUpdateInfo:info
//                                            runner:runner
//                                     userInitiated:ui];
//
//   [ap enqueueAction:action];
//   [ap startProcessing];
//
// The above code will create a KSUpdateAction that will download a DMG then
// run the Keystone install scripts on the downloaded DMG. If either the
// download or the install fails, the KSUpdateAction itself will fail.
@interface KSUpdateAction : KSCompositeAction {
 @private
  KSUpdateInfo *updateInfo_;
}

+ (id)actionWithUpdateInfo:(KSUpdateInfo *)info
                    runner:(id<KSCommandRunner>)runner
             userInitiated:(BOOL)ui;

// Designated initializer. 
- (id)initWithUpdateInfo:(KSUpdateInfo *)info
                  runner:(id<KSCommandRunner>)runner
           userInitiated:(BOOL)ui;

// Returns the KSUpdateInfo for this update action.
- (KSUpdateInfo *)updateInfo;

// Returns the return code (i.e., exit status) of the update. See
// KSInstallAction for details about the possible return codes. If the download
// fails and the update install was never attempted, nil is returned. Otherwise,
// the returned NSNumber matches the returned int value from the
// KSInstallAction.
//
// If an error occurs and the KSInstallAction is never attempted (e.g., the 
// download fails), -returnCode will return an NSNumber for -1.
- (NSNumber *)returnCode;

// Returns YES if the complete update action requested a reboot, NO otherwise.
// This method should only be called once the KSUpdateAction completes. If it is
// called before completion, the return value is undefined.
- (BOOL)wantsReboot;

@end
