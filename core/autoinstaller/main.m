//
//  main.m
//  autoinstaller
//
//  Created by Greg Miller on 7/10/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KeystoneDelegate.h"
#import "KSKeystone.h"
#import "KSExistenceChecker.h"
#import "KSTicket.h"
#import "KSMemoryTicketStore.h"
#import "GMLogger.h"
#import "GTMScriptRunner.h"
#import <getopt.h>
#import <stdio.h>
#import <unistd.h>


// The URL to the KSPlistServer-style rules plist to use for MacFUSE updates.
static NSString* const kDefaultRulesURL =
  @"http://macfuse.googlecode.com/svn/trunk/CurrentRelease.plist";


// Usage
//
// Prints usage information about this command line program.
//
static void Usage(void) {
  printf("Usage: macfuse_autoinstaller -[pliv]\n"
         "  --print,-p    Print info about the currently installed MacFUSE\n"
         "  --list,-l     List MacFUSE update, if one is available\n"
         "  --install,-i  Download and install MacFUSE update, if available\n"
         "  --verbose,-v  Print VERY verbose output\n"
  );
}


// IsTiger
//
// Returns YES if the current OS is Tiger, NO otherwise.
//
static BOOL IsTiger(void) {
  NSDictionary *sysVersion =
    [NSDictionary dictionaryWithContentsOfFile:
     @"/System/Library/CoreServices/SystemVersion.plist"];
  return [[sysVersion objectForKey:@"ProductVersion"] hasPrefix:@"10.4"];
}


// GetMacFUSEVersion
//
// Returns the version of the currently-installed MacFUSE. If not found, returns
// nil. The version is obtained by running:
//
//   MOUNT_FUSEFS_CALL_BY_LIB=1 .../mount_fusefs --version
//
static NSString *GetMacFUSEVersion(void) {
  NSString *mountFusePath =
    @"/Library/Filesystems/fusefs.fs/Support/mount_fusefs";
  
  if (IsTiger()) {
    mountFusePath = [@"/System" stringByAppendingPathComponent:mountFusePath];
  }
  
  NSString *cmd = [NSString stringWithFormat:
                   @"MOUNT_FUSEFS_CALL_BY_LIB=1 "
                   @"%@ --version 2>&1 | /usr/bin/awk '{print $NF}'",
                   mountFusePath];
  
  GTMScriptRunner *runner = [GTMScriptRunner runnerWithBash];
  return [runner run:cmd];
}


// GetMacFUSETicket
// 
// Returns a KSTicket that represents the currently installed MacFUSE instance.
// If MacFUSE is not currently installed, the version number in the returned 
// ticket will be "0", and the existence checker will reference "/".
//
static KSTicket *GetMacFUSETicket(NSString *ticketUrl) {
  NSURL *url = [NSURL URLWithString:ticketUrl];
  NSString *version = @"0";
  KSExistenceChecker *xc = [KSPathExistenceChecker checkerWithPath:@"/"];

  NSString *installedVersion = GetMacFUSEVersion();
  if (installedVersion != nil) {
    version = installedVersion;
  }

  return [KSTicket ticketWithProductID:@"com.google.filesystems.fusefs"
                               version:version
                      existenceChecker:xc
                             serverURL:url];
}

// main
//
// Parses command-line options, gets the ticket for the currently-installed
// version of MacFUSE, stuffs that in a KSTicketStore, then finally creates
// a KSKeystone instance to drive the install/update with this ticket store and
// a custom delegate.
//
int main(int argc, char **argv) {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  int rc = 0;

  static struct option kLongOpts[] = {
    { "print",         no_argument,       NULL, 'p' },
    { "list",          no_argument,       NULL, 'l' },
    { "install",       no_argument,       NULL, 'i' },
    { "verbose",       no_argument,       NULL, 'v' },
    { "url",           required_argument, NULL, 'u' },
    {  NULL,           0,                 NULL,  0  },
  };
  
  BOOL print = NO, list = NO, install = NO, verbose = NO;
  const char *url = NULL;
  int ch = 0;
  while ((ch = getopt_long(argc, argv, "pliv", kLongOpts, NULL)) != -1) {
    switch (ch) {
      case 'p':
        print = YES;
        break;
      case 'l':
        list = YES;
        break;
      case 'i':
        install = YES;
        break;
      case 'v':
        verbose = YES;
        break;
      case 'u':
        url = optarg;
        break;
      default:
        Usage();
        goto done;
    }
  }
  
  if (verbose) {
    [[GMLogger sharedLogger] setFilter:nil];  // Remove log filtering
  }
  
  NSString *rulesUrl = url
    ? [NSString stringWithUTF8String:url] 
    : kDefaultRulesURL;
  KSTicket *macfuseTicket = GetMacFUSETicket(rulesUrl);
  if (print) {
    printf("%s\n", [[macfuseTicket description] UTF8String]);
    goto done;
  }
  
  KSTicketStore *store = [[[KSMemoryTicketStore alloc] init] autorelease];
  if (![store storeTicket:macfuseTicket]) {
    fprintf(stderr, "Failed to store ticket %s\n", 
            [[macfuseTicket description] UTF8String]);
    goto done;
  }
  
  // If neither list nor install was specified, we don't have anything to do
  if (!list && !install) {
    Usage();
    goto done;
  }
  
  // Can't install a MacFUSE update w/o being root. 
  if (install && geteuid() != 0) {
    fprintf(stderr, "Must be root.\n");
    rc = 1;
    goto done;
  }
  
  KeystoneDelegate *delegate = [[[KeystoneDelegate alloc]
                                 initWithList:list
                                      install:install] autorelease];
  
  // Create a KSKeystone instance with our ticket store that only contains one
  // ticket (for MacFUSE itself), and our custom delegate that knows how to
  // handle installing/listing the available updates. Then, tell that keystone 
  // to update everything. This will kick off Keystone's update engine, but our
  // delegate will be able to customize the experience.
  KSKeystone *keystone = [KSKeystone keystoneWithTicketStore:store
                                                    delegate:delegate];
  [keystone updateAllProducts];
  
  while ([keystone isUpdating]) {
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0.2];
    [[NSRunLoop currentRunLoop] runUntilDate:date];
  }
  
  if (![delegate wasSuccess]) {
    printf("  *** Updated failed. Rerun with -v for details.\n");
    rc = 1;
  }
    
done:
  [pool release];
  return rc;
}
