//
//  AFHTTPClientTests.m
//  AFNetworking
//
//  Created by Blake Watters on 5/10/13.
//  Copyright (c) 2013 AFNetworking. All rights reserved.
//

#import "AFNetworkingTests.h"

@interface AFHTTPClientTests : SenTestCase
@property (readwrite, nonatomic, strong) AFHTTPClient *client;
@end

@implementation AFHTTPClientTests
@synthesize client = _client;

- (void)setUp {
    self.client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:AFNetworkingTestsBaseURLString]];
}

#pragma mark -

- (void)testThatTheDefaultStringEncodingIsUTF8 {
    expect(self.client.stringEncoding).to.equal(NSUTF8StringEncoding);
}

- (void)testConstructingPOSTRequestWithParametersInFormURLParameterEncoding {
    self.client.parameterEncoding = AFFormURLParameterEncoding;
    
    NSMutableURLRequest *request = [self.client requestWithMethod:@"POST" path:@"/post" parameters:@{ @"key": @"value" }];
    NSString *requestBody = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];
    expect(requestBody).to.equal(@"key=value");
}

- (void)testConstructingPOSTRequestWithParametersInJSONParameterEncoding {
    self.client.parameterEncoding = AFJSONParameterEncoding;
    
    NSMutableURLRequest *request = [self.client requestWithMethod:@"POST" path:@"/post" parameters:@{ @"key": @"value" }];
    NSString *requestBody = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];
    expect(requestBody).to.equal(@"{\"key\":\"value\"}");
}

- (void)testConstructingPOSTRequestWithParametersInPropertyListParameterEncoding {
    self.client.parameterEncoding = AFPropertyListParameterEncoding;
    
    NSMutableURLRequest *request = [self.client requestWithMethod:@"POST" path:@"/post" parameters:@{ @"key": @"value" }];
    NSString *requestBody = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];
    expect(requestBody).to.equal(@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n<plist version=\"1.0\">\n<dict>\n	<key>key</key>\n	<string>value</string>\n</dict>\n</plist>\n");
}

- (void)testPostWithParameters {
    __block id blockResponseObject = nil;
    [self.client postPath:@"/post" parameters:@{ @"key": @"value" } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        blockResponseObject = responseObject;
    } failure:nil];
    
    expect([self.client.operationQueue operationCount]).will.equal(0);
    expect(blockResponseObject).notTo.beNil();
    expect(blockResponseObject).to.beKindOf([NSData class]);
    
    NSError *error = nil;
    NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:blockResponseObject options:0 error:&error];
    expect(responseDictionary[@"form"]).to.equal(@{ @"key": @"value" });
}

@end
