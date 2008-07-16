//
//  KSKeystoneParameters.h
//  Keystone
//
//  Created by John Grabowski on 4/29/08
//  Copyright 2008 Google Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

// Dictionary keys for parameters passed to a KSKeystone from its
// acquirer.  All values for these keys should be NSStrings unless
// otherwise specified.  GUIDs (also as NSStrings) should be specified
// in the convention initiated by the Omaha client; i.e. curly
// brackets around a number, like {0000-1111-blah}.
#define kKeystoneMachineID              @"MachineID"
#define kKeystoneUserGUID               @"UserGUID"
#define kKeystoneOSVersion              @"OSVersion"    // e.g. "10.5.2_x86"
#define kKeystoneUpdateCheckTag         @"UpdateCheckTag"
#define kKeystoneIsMachine              @"IsMachine"
