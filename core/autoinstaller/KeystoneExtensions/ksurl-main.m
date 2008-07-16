//
//  ksurl-main.m
//  Keystone
//
//  Created by Greg Miller on 2/27/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import <unistd.h>
#import <pwd.h>
#import <Foundation/Foundation.h>


// We use NSLog here to avoid the dependency on non-default frameworks.


// DownloadDelegate
//
// The delegate for NSURLDownload. It simply sets some internal flags when a
// download finishes to indicate whether the download finished successfully.
@interface DownloadDelegate : NSObject {
 @private
  BOOL done_;
  BOOL success_;
}

// Returns YES if the download has finished, NO otherwise.
- (BOOL)isDone;

// Returns YES if the download completed successfully, NO otherwise.
- (BOOL)wasSuccess;

@end


@implementation DownloadDelegate

- (BOOL)isDone {
  return done_;
}

- (BOOL)wasSuccess {
  return success_;
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error {
  NSLog(@"Download (%@) failed with error - %@ %@",
        download, [error localizedDescription],
        [[error userInfo] objectForKey:NSErrorFailingURLStringKey]);
  done_ = YES;
  success_ = NO;
}

- (void)downloadDidFinish:(NSURLDownload *)download {
  done_ = YES;
  success_ = YES;
}

@end


// A command-line URL fetcher (ksurl, like "curl"). It requires the following
// two command-line arguments:
//   -url <url>    the URL to be downloaded (e.g. http://www.google.com)
//   -path <path>  the local path where the downloaded file should be stored
//
// We do not provide a help screen because this command is not a "public" API
// and it would only increase our file size and encourage its use. Actually,
// *we* may not even use this command, in which case we'll remove it.
int main(void) {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  int rc = EXIT_FAILURE;
  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  
  NSString *urlString = [defaults stringForKey:@"url"];
  if (urlString == nil) goto bail;
  
  NSURL *url = [NSURL URLWithString:urlString];
  if (url == nil) goto bail;
  
  NSString *path = [defaults stringForKey:@"path"];
  if (path == nil) goto bail;
  
  // If we're running as root, change uid and group id to "nobody"
  if (geteuid() == 0 || getuid() == 0) {
    // COV_NF_START
    setgid(-2);
    setuid(-2);
    if (geteuid() == 0 || getuid() == 0 || getgid() == 0) {
      NSLog(@"Failed to change uid to -2");
      goto bail;
    }
    //COV_NF_END
  }
  
  NSURLRequest *request = nil;
  request = [NSURLRequest requestWithURL:url
                             cachePolicy:NSURLRequestUseProtocolCachePolicy
                         timeoutInterval:60];
  
  DownloadDelegate *delegate = [[[DownloadDelegate alloc] init] autorelease];
  NSURLDownload *download = 
    [[[NSURLDownload alloc] initWithRequest:request
                                   delegate:delegate] autorelease];
  
  [download setDestination:path allowOverwrite:YES];
  
  // Wait for the download to complete.
  while (![delegate isDone]) {
    NSDate *spin = [NSDate dateWithTimeIntervalSinceNow:1];
    [[NSRunLoop currentRunLoop] runUntilDate:spin];
  }
  
  if ([delegate wasSuccess])
    rc = EXIT_SUCCESS;
  
bail:
  [pool release];
  return rc;
}
