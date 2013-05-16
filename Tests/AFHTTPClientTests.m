// AFHTTPClientTests.m
//
// Copyright (c) 2013 AFNetworking (http://afnetworking.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

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
