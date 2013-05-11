//
//  AFHTTPClientTest.m
//  AFNetworking
//
//  Created by Blake Watters on 5/10/13.
//  Copyright (c) 2013 AFNetworking. All rights reserved.
//

#import "AFNetworkingTests.h"

@interface AFHTTPClientTest : SenTestCase
@end

@implementation AFHTTPClientTest

- (void)testThatTheDefaultStringEncodingIsUTF8
{
    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:AFNetworkingTestsBaseURLString]];
    expect(client.stringEncoding).to.equal(NSUTF8StringEncoding);
}

// default value for header

@end
