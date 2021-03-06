//
//  SignedPlistServer.m
//  autoinstaller
//
//  Created by Greg Miller on 7/15/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import "SignedPlistServer.h"
#import "Signer.h"
#import "PlistSigner.h"
#import "GTMLogger.h"


// Public Key for officially signed MacFUSE rules plists
static unsigned char macfuse_public_der[] = {
0x30, 0x81, 0x9f, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7,
0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x81, 0x8d, 0x00, 0x30, 0x81,
0x89, 0x02, 0x81, 0x81, 0x00, 0xc6, 0xed, 0xf8, 0x40, 0x75, 0xd0, 0x86,
0xe8, 0xd5, 0xc7, 0x9d, 0xd8, 0xba, 0x10, 0x91, 0x23, 0xd1, 0xfa, 0x3a,
0x2a, 0x1f, 0xb8, 0xe9, 0xbf, 0x3e, 0x55, 0xe2, 0x67, 0x30, 0x2f, 0xa1,
0x43, 0x51, 0xe4, 0xe3, 0xdb, 0x71, 0x7a, 0x30, 0x1d, 0xb3, 0xe8, 0x3d,
0x74, 0x1f, 0x07, 0x57, 0xf7, 0x17, 0x69, 0x3d, 0x1b, 0xda, 0x0a, 0x61,
0x78, 0x59, 0x27, 0xa5, 0x59, 0x56, 0x77, 0xcc, 0xa8, 0x09, 0x96, 0xd0,
0x6f, 0xe7, 0xfb, 0x3a, 0xd0, 0x0a, 0xed, 0x0b, 0xad, 0x2c, 0xc7, 0x83,
0x1d, 0x53, 0x07, 0xf4, 0x17, 0x5b, 0x1c, 0x39, 0x8e, 0x47, 0x42, 0x8b,
0x53, 0xc4, 0xd1, 0x11, 0x68, 0x1c, 0x69, 0x11, 0x2a, 0x22, 0xc9, 0x5b,
0x4e, 0xda, 0xf6, 0x39, 0x98, 0x46, 0x91, 0xf9, 0x13, 0x1f, 0x11, 0xb8,
0xaf, 0x5e, 0x10, 0xa5, 0x2f, 0x40, 0x83, 0x27, 0x77, 0x7a, 0x67, 0x00,
0x01, 0x02, 0x03, 0x01, 0x00, 0x01
};
static unsigned int macfuse_public_der_len = 162;


@implementation SignedPlistServer

- (id)initWithURL:(NSURL *)url params:(NSDictionary *)params {
  // By default, this class will create a SignedPlistServer customized with 
  // the appropriate public key for the signature of MacFUSE rules plists.
  NSData *pubKey = [NSData dataWithBytes:macfuse_public_der
                                  length:macfuse_public_der_len];
  Signer *macfuseSigner = [Signer signerWithPublicKey:pubKey privateKey:nil];
  return [self initWithURL:url signer:macfuseSigner];
}

- (id)initWithURL:(NSURL *)url signer:(Signer *)signer {
  if ((self = [super initWithURL:url params:nil])) {
    signer_ = [signer retain];
    if (signer_ == nil) {
      [self release];
      return nil;
    }
  }
  return self;
}

- (void)dealloc {
  [signer_ release];
  [super dealloc];
}

- (NSArray *)updateInfosForResponse:(NSURLResponse *)response
                               data:(NSData *)data {
  // Decode the response |data| into a plist
  NSString *body = [[[NSString alloc]
                     initWithData:data
                     encoding:NSUTF8StringEncoding] autorelease];
  NSDictionary *plist = nil;
  @try {
    // This method can throw if |body| isn't a valid plist
    plist = [body propertyList];
  }
  @catch (id ex) {
    GTMLoggerError(@"Failed to parse response into plist: %@", ex);
    return nil;
  }

  PlistSigner *plistSigner = [[[PlistSigner alloc]
                               initWithSigner:signer_
                                        plist:plist] autorelease];
  
  if (![plistSigner isPlistSigned]) {
    GTMLoggerInfo(@"Ignoring plist with bad signature (plistSigner=%@)\n%@",
                  plistSigner, body);
    return nil;
  }
  
  return [super updateInfosForResponse:response data:data];
}

@end
