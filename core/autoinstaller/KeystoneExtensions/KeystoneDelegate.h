//
//  KeystoneDelegate.h
//  autoinstaller
//
//  Created by Greg Miller on 7/10/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


// KeystoneDelegate
//
// The MacFUSE autoinstaller's delegate object for a KSKeystone instance.
// This object is created with two BOOLs indicating whether the available
// updates should be installed, or simply listed. If both |install| and |list|
// are YES, then |list| is used.
//
@interface KeystoneDelegate : NSObject {
 @private
  BOOL list_;
  BOOL install_;
  BOOL wasSuccess_;
}

// Designated initializer.
- (id)initWithList:(BOOL)list install:(BOOL)install;

// Returns whether the MacFUSE update was successful.
- (BOOL)wasSuccess;

@end
