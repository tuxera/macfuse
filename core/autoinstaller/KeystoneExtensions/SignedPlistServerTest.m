//
//  SignedPlistServerTest.m
//  autoinstaller
//
//  Created by Greg Miller on 7/18/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "KSExistenceChecker.h"
#import "KSTicket.h"
#import "SignedPlistServer.h"
#import "Signer.h"


static unsigned char public_key_der[] = {
0x30, 0x81, 0x9f, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7,
0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x81, 0x8d, 0x00, 0x30, 0x81,
0x89, 0x02, 0x81, 0x81, 0x00, 0xc7, 0xa2, 0x29, 0x0e, 0xc7, 0xf2, 0x15,
0x21, 0x46, 0x01, 0x44, 0x89, 0x5a, 0x78, 0x4b, 0xe5, 0x07, 0x8d, 0x69,
0x80, 0x69, 0x98, 0xd8, 0x5c, 0x89, 0x5c, 0x5d, 0xe6, 0x52, 0x02, 0xc4,
0x58, 0x28, 0xad, 0xdb, 0x7a, 0x62, 0x12, 0x38, 0x1d, 0x3a, 0xef, 0x82,
0xf9, 0xfe, 0x97, 0x99, 0x82, 0x38, 0x9e, 0x9f, 0x76, 0x47, 0x8d, 0x10,
0x63, 0x1a, 0xfa, 0x70, 0x17, 0x03, 0x4c, 0x3d, 0x80, 0x17, 0xd2, 0xb0,
0x76, 0xcb, 0x60, 0xd9, 0xa3, 0xe9, 0x52, 0x4e, 0x18, 0x62, 0x6e, 0x3a,
0xa7, 0xf5, 0x19, 0x2f, 0x6e, 0x9c, 0x6a, 0xfa, 0xd0, 0x05, 0x5f, 0xca,
0x88, 0xb7, 0x17, 0xc1, 0x3a, 0xe3, 0x30, 0x88, 0x2e, 0xcd, 0x69, 0xae,
0xe8, 0x67, 0x62, 0xe9, 0x3a, 0xaa, 0xaa, 0x55, 0x50, 0xab, 0xfa, 0xe5,
0x26, 0xbe, 0x61, 0xa7, 0xb4, 0x7b, 0x3a, 0xa6, 0x6f, 0x72, 0x80, 0xb9,
0xb7, 0x02, 0x03, 0x01, 0x00, 0x01
};
static unsigned int public_key_der_len = 162;


static NSString *const kUnsignedPlist = 
@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
@"<!DOCTYPE plist PUBLIC \"-//Apple Computer//DTD PLIST 1.0//EN\""
@"                       \"https://www.apple.com/DTDs/PropertyList-1.0.dtd\">"
@"<plist version=\"1.0\">"
@"<dict>"
@"  <key>Rules</key>"
@"  <array>"
@"    <dict>"
@"      <key>ProductID</key>"
@"      <string>com.google.Foo</string>"
@"      <key>Predicate</key>"
@"      <string>1 == 1</string>"
@"      <key>Codebase</key>"
@"      <string>https://www.google.com/keystone/Foo.dmg</string>"
@"      <key>Hash</key>"
@"      <string>somehash=</string>"
@"      <key>Size</key>"
@"      <string>123456</string>"
@"    </dict>"
@"  </array>"
@"</dict>"
@"</plist>"
;

static NSString *const kSignedPlist = 
@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
@"<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">"
@"<plist version=\"1.0\">"
@"<dict>"
@"	<key>Rules</key>"
@"	<array>"
@"		<dict>"
@"			<key>Codebase</key>"
@"			<string>http://macfuse.googlecode.com/svn/releases/MacFUSE-1.7.dmg</string>"
@"			<key>Hash</key>"
@"			<string>9I5CFGd/dHClCLycl2UJlvW3LKg=</string>"
@"			<key>Predicate</key>"
@"			<string>1 == 1</string>"
@"			<key>ProductID</key>"
@"			<string>com.google.filesystems.fusefs</string>"
@"			<key>Size</key>"
@"			<string>1732368</string>"
@"			<key>Version</key>"
@"			<string>1.7.1</string>"
@"		</dict>"
@"	</array>"
@"	<key>Signature</key>"
@"	<data>"
@"	jWUbl4GcsH0YETYZPHTew20t98fT7zKGImJ/9en5EvGdi3Nj5E2D+/0xlU+wEbjkw2qg"
@"	DemIvCEy0Xp+p8AoSVPRdWyY7LY+erLlkT7osELfU3rneXh4x2/n54CdNUxkTY9zuCev"
@"	G/n9Ab29qepYDYYVLdRZLOkeBpyHVBvtHGk="
@"	</data>"
@"</dict>"
@"</plist>"
;


@interface SignedPlistServerTest : SenTestCase {
 @private
  NSURL *url_;
  Signer *signer_;
  SignedPlistServer *server_;
}
@end

@implementation SignedPlistServerTest

- (void)setUp {
  NSData *pubKey = [NSData dataWithBytes:public_key_der
                                  length:public_key_der_len];
  signer_ = [[Signer alloc] initWithPublicKey:pubKey privateKey:nil];
  STAssertNotNil(signer_, nil);
  
  url_ = [[NSURL alloc] initWithString:
           @"http://macfuse.googlecode.com/svn/trunk/CurrentRelease.plist"];
  STAssertNotNil(url_, nil);
  
  server_ = [[SignedPlistServer alloc] initWithURL:url_
                                            signer:signer_];
  STAssertNotNil(server_, nil);
  
  KSExistenceChecker *xc = [KSPathExistenceChecker checkerWithPath:@"/"];
  KSTicket *fakeTicket = [KSTicket ticketWithProductID:@"com.google.filesystems.fusefs"
                                               version:@"0"
                                      existenceChecker:xc
                                             serverURL:url_];
  [server_ requestsForTickets:[NSArray arrayWithObject:fakeTicket]];
}

- (void)tearDown {
  [signer_ release];
  [url_ release];
  [server_ release];
}

- (void)testCreation {  
  SignedPlistServer *server = [[[SignedPlistServer alloc] init] autorelease];
  STAssertNil(server, nil);
  
  server = [[[SignedPlistServer alloc] initWithURL:url_] autorelease];
  STAssertNotNil(server, nil);
  
  server = [[[SignedPlistServer alloc] initWithURL:url_
                                            signer:signer_] autorelease];
  STAssertNotNil(server, nil);
}

- (void)testUnsignedPlist {
  NSDictionary *plist = [kUnsignedPlist propertyList];
  NSData *plistData = [NSPropertyListSerialization
                       dataFromPropertyList:plist
                       format:NSPropertyListXMLFormat_v1_0
                       errorDescription:NULL];
  NSArray *infos = [server_ updateInfosForResponse:nil data:plistData];
  STAssertNil(infos, nil);
}

- (void)testSignedPlist {
  NSDictionary *plist = [kSignedPlist propertyList];
  NSData *plistData = [NSPropertyListSerialization
                       dataFromPropertyList:plist
                       format:NSPropertyListXMLFormat_v1_0
                       errorDescription:NULL];
  NSArray *infos = [server_ updateInfosForResponse:nil data:plistData];
  STAssertNotNil(infos, nil);
  STAssertTrue([infos count] == 1, nil);
}

@end
