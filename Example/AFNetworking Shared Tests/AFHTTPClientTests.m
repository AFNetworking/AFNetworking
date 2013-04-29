//
//  AFHTTPClientTests.m
//  AFNetworking Shared Example
//
//  Created by Stan Chang Khin Boon on 10/4/13.
//
//

#import "AFHTTPClientTests.h"
#import "AFHTTPClient.h"

@implementation AFHTTPClientTests

- (void)testInitialization {
    NSURL *googleURL = [NSURL URLWithString:@"http://www.google.com"];
    AFHTTPClient *client = nil;
    STAssertNoThrow(client = [[AFHTTPClient alloc] initWithBaseURL:googleURL], @"If base URL is valid during initialization, no exception is thrown.");
    STAssertNotNil(client, @"If base URL is valid during initialization, client will not be nil.");
    
    STAssertThrowsSpecificNamed((void)[[AFHTTPClient alloc] initWithBaseURL:nil], NSException, NSInternalInconsistencyException, @"If base URL is nil during initialization, an exception is thrown.");
}

@end
