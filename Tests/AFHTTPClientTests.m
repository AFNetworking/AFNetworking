//
//  AFHTTPClientTests.m
//  AFNetworking
//
//  Created by Blake Watters on 5/10/13.
//  Copyright (c) 2013 AFNetworking. All rights reserved.
//

#import "AFNetworkingTests.h"

@interface AFHTTPClientTests : SenTestCase
@end

@implementation AFHTTPClientTests

- (void)testThatTheDefaultStringEncodingIsUTF8
{
    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:AFNetworkingTestsBaseURLString]];
    expect(client.stringEncoding).to.equal(NSUTF8StringEncoding);
}

- (void)testConstructingPOSTRequestWithParametersInFormURLParameterEncoding
{
    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:AFNetworkingTestsBaseURLString]];
    client.parameterEncoding = AFFormURLParameterEncoding;
    NSMutableURLRequest *request = [client requestWithMethod:@"POST" path:@"/post" parameters:@{ @"key": @"value" }];
    NSString *requestBody = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];
    expect(requestBody).to.equal(@"key=value");
}

- (void)testConstructingPOSTRequestWithParametersInJSONParameterEncoding
{
    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:AFNetworkingTestsBaseURLString]];
    client.parameterEncoding = AFJSONParameterEncoding;
    NSMutableURLRequest *request = [client requestWithMethod:@"POST" path:@"/post" parameters:@{ @"key": @"value" }];
    NSString *requestBody = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];
    expect(requestBody).to.equal(@"{\"key\":\"value\"}");
}

- (void)testConstructingPOSTRequestWithParametersInPropertyListParameterEncoding
{
    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:AFNetworkingTestsBaseURLString]];
    client.parameterEncoding = AFPropertyListParameterEncoding;
    NSMutableURLRequest *request = [client requestWithMethod:@"POST" path:@"/post" parameters:@{ @"key": @"value" }];
    NSString *requestBody = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];
    expect(requestBody).to.equal(@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n<plist version=\"1.0\">\n<dict>\n	<key>key</key>\n	<string>value</string>\n</dict>\n</plist>\n");
}

- (void)testPostWithParameters
{
    __block id blockResponseObject = nil;
    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:AFNetworkingTestsBaseURLString]];
    [client postPath:@"/post" parameters:@{ @"key": @"value" } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        blockResponseObject = responseObject;
    } failure:nil];
    expect([client.operationQueue operationCount]).will.equal(0);
    expect(blockResponseObject).notTo.beNil();
    expect(blockResponseObject).to.beKindOf([NSData class]);
    NSError *error = nil;
    NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:blockResponseObject options:0 error:&error];
    expect(responseDictionary[@"form"]).to.equal(@{ @"key": @"value" });
}

// default value for header

@end
