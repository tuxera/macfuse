//
//  KSInstallAction.m
//  Keystone
//
//  Created by Greg Miller on 1/28/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import "KSInstallAction.h"
#import "KSActionProcessor.h"
#import "KSActionPipe.h"
#import "KSCommandRunner.h"
#import "KSDiskImage.h"
#import "GMLogger.h"
#import "GTMDefines.h"


// Install script names that may appear at the top level of the dmg
static NSString *const kPreinstallScriptName  = @".keystone_preinstall";
static NSString *const kInstallScriptName     = @".keystone_install";
static NSString *const kPostinstallScriptName = @".keystone_postinstall";


@interface KSInstallAction (PrivateMethods)
- (NSString *)keystoneToolsPath;
- (void)addUpdateInfoToEnvironment:(NSMutableDictionary *)env;
- (BOOL)isPathToExecutableFile:(NSString *)path;
@end


@implementation KSInstallAction

+ (id)actionWithDMGPath:(NSString *)path
                 runner:(id<KSCommandRunner>)runner
          userInitiated:(BOOL)ui {
  return [self actionWithDMGPath:path
                          runner:runner
                   userInitiated:ui
                      updateInfo:nil];
}

+ (id)actionWithDMGPath:(NSString *)path
                 runner:(id<KSCommandRunner>)runner
          userInitiated:(BOOL)ui
             updateInfo:(KSUpdateInfo *)updateInfo {
  return [[[self alloc] initWithDMGPath:path
                                 runner:runner
                          userInitiated:ui
                             updateInfo:updateInfo] autorelease];
}

- (id)init {
  return [self initWithDMGPath:nil runner:nil userInitiated:NO updateInfo:nil];
}

- (id)initWithDMGPath:(NSString *)path
               runner:(id<KSCommandRunner>)runner
        userInitiated:(BOOL)ui
           updateInfo:(KSUpdateInfo *)updateInfo {
  if ((self = [super init])) {
    [self setInPipe:[KSActionPipe pipeWithContents:path]];
    runner_ = [runner retain];
    ui_ = ui;
    updateInfo_ = [updateInfo retain];  // allowed to be nil
    
    if (runner_ == nil) {
      GMLoggerDebug(@"created with illegal argument: "
                    @"runner=%@, ui=%d", runner_, ui_);
      [self release];
      return nil;
    }
  }
  return self;
}

- (void)dealloc {
  [runner_ release];
  [updateInfo_ release];
  [super dealloc];
}

- (NSString *)dmgPath {
  return [[self inPipe] contents];
}

- (id<KSCommandRunner>)runner {
  return runner_;
}

- (BOOL)userInitiated {
  return ui_;
}

- (void)performAction {
  // When this method is called, we'll mount a disk and run some install 
  // scripts, so it's important that we don't terminate before we're all done.
  // This means that if this action is terminated (via -terminateAction), we
  // *still* want to run to completion. If this happens, we need to guarantee
  // that this object ("self") stays around until this method completes. Which
  // is why we retain ourself on the first line, and release on the last line.
  [self retain];
  
  // Assert class invariants that we care about here
  _GTMDevAssert(runner_ != nil, @"runner_ must not be nil");
   
  int rc = 1;  // non-zero is failure
  BOOL success = NO;
  
  KSDiskImage *diskImage = [KSDiskImage diskImageWithPath:[self dmgPath]];
  NSString *mountPoint = [diskImage mount];
  if (mountPoint == nil) {
    GMLoggerError(@"Failed to mount %@", [self dmgPath]);
    rc = 1;
    success = NO;
    goto bail_no_unmount;
  }
  
  NSString *script1 = [mountPoint stringByAppendingPathComponent:kPreinstallScriptName];
  NSString *script2 = [mountPoint stringByAppendingPathComponent:kInstallScriptName];
  NSString *script3 = [mountPoint stringByAppendingPathComponent:kPostinstallScriptName];
  
  if (![self isPathToExecutableFile:script2]) {
    // This script is the ".keystone_install" script, and it MUST exist
    GMLoggerError(@"%@ does not exist", script2);
    success = NO;
    goto bail;
  }
  
  NSString *output1 = nil;
  NSString *output2 = nil;
  NSString *output3 = nil;
  // We don't care about output3, but we pass it on anyway because
  // it's required by -runCommand.
  
  NSArray *args = [NSArray arrayWithObject:mountPoint];
  NSMutableDictionary *env = [NSMutableDictionary dictionary];
  
  // Start off by adding all of the keys in |updateInfo_| to the environment, 
  // but prepend them all with some unique string.
  [self addUpdateInfoToEnvironment:env];
  
  // Set a good default path that starts with the directory containing Keystone
  // Tools, such as ksadmin. This allows the scripts to be able to use Keystone
  // commands without having to know where they're located.
  NSString *toolsPath = [self keystoneToolsPath];
  NSString *path = [NSString stringWithFormat:@"%@:/bin:/usr/bin", toolsPath];
  [env setObject:path forKey:@"PATH"];
  
  [env setObject:(ui_ ? @"YES" : @"NO") forKey:@"KS_USER_INITIATED"];
    
  //
  // Script 1
  //
  if ([self isPathToExecutableFile:script1]) {
    @try {
      rc = 1;  // non-zero is failure
      rc = [runner_ runCommand:script1
                      withArgs:args
                   environment:env
                        output:&output1];
    }
    @catch (id ex) {
      GMLoggerError(@"Caught exception from runner_ (script1): %@", ex);      
    }
    if (rc != KS_INSTALL_SUCCESS) {
      success = NO;
      goto bail;
    }
  }
  [env setObject:(output1 ? output1 : @"") forKey:@"KS_PREINSTALL_OUT"];
  
  //
  // Script 2
  //
  if ([self isPathToExecutableFile:script2]) {
    // Notice that this "runCommand" is different from the other two because
    // this one is sent to "self", whereas the other two are sent to the
    // runner. This is because the pre/post-install scripts need to be
    // executed by the console user, but the install script must be run as 
    // *this* user (where, "this" user might be root).
    @try {
      rc = 1;  // non-zero is failure
      rc = [[KSTaskCommandRunner commandRunner] runCommand:script2
                                                  withArgs:args
                                               environment:env
                                                    output:&output2]; 
    }
    @catch (id ex) {
      GMLoggerError(@"Caught exception from runner_ (script2): %@", ex);      
    }
    if (rc != KS_INSTALL_SUCCESS) {
      success = NO;
      goto bail;
    }
  }
  [env setObject:(output2 ? output2 : @"") forKey:@"KS_INSTALL_OUT"];
  
  //
  // Script 3
  //
  if ([self isPathToExecutableFile:script3]) {
    @try {
      rc = 1;  // non-zero is failure
      rc = [runner_ runCommand:script3
                      withArgs:args
                   environment:env
                        output:&output3];
    }
    @catch (id ex) {
      GMLoggerError(@"Caught exception from runner_ (script3): %@", ex);      
    }
    if (rc != KS_INSTALL_SUCCESS) {
      success = NO;
      goto bail;
    }
  }  
  
  success = YES;
  
bail:
  if (![diskImage unmount])
    GMLoggerError(@"Failed to unmount %@", mountPoint);  // COV_NF_LINE

bail_no_unmount:
  // Treat "try again later" and "requires reboot" return codes as successes.
  if (rc == KS_INSTALL_TRY_AGAIN_LATER || rc == KS_INSTALL_WANTS_REBOOT)
    success = YES;
  
  [[self outPipe] setContents:[NSNumber numberWithInt:rc]];
  [[self processor] finishedProcessing:self successfully:success];
  
  // Balance our retain on the first line of this method
  [self release];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@:%p inPipe=%@ outPipe=%@>",
                   [self class], self, [self inPipe], [self outPipe]];
}

@end  // KSInstallAction


@implementation KSInstallAction (PrivateMethods)

// Returns the path to the directory that contains "ksadmin". Yes, this is an 
// ugly hack because it forces an ugly dependency on this framework.
// Specifically, the Keystone framework must be located in a directory that is
// a peer to a MacOS directory, which must contain the "ksadmin" command. Yeah.
// ... but hey, it might make someone else's life a bit easier.
- (NSString *)keystoneToolsPath {
  NSBundle *framework = [NSBundle bundleForClass:[KSInstallAction class]];
  return [NSString stringWithFormat:@"%@/../../MacOS", [framework bundlePath]];
}

// Add all of the objects in |updateInfo_| to the mutable dictionary |env|, but
// prepend all of updateInfo_'s keys with the string @"KS_". This avoids the
// possibility that someone's Omaha config conflits w/ an actual shell variable.
- (void)addUpdateInfoToEnvironment:(NSMutableDictionary *)env {
  NSString *key = nil;
  NSEnumerator *keyEnumerator = [updateInfo_ keyEnumerator];
  
  while ((key = [keyEnumerator nextObject])) {
    [env setObject:[[updateInfo_ objectForKey:key] description]
            forKey:[@"KS_" stringByAppendingString:key]];
  }
}

- (BOOL)isPathToExecutableFile:(NSString *)path {
  NSFileManager *fm = [NSFileManager defaultManager];
  BOOL isDir;

  if ([fm fileExistsAtPath:path isDirectory:&isDir] && !isDir) {
    return [fm isExecutableFileAtPath:path];
  } else {
    return NO;
  }
}

@end  // PrivateMethods
