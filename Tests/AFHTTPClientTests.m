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

- (void)testDefaultHeaders {
    [self.client setDefaultHeader:@"x-some-key" value:@"SomeValue"];
    expect([self.client defaultValueForHeader:@"x-some-key"]).to.equal(@"SomeValue");
    
    NSMutableURLRequest *request = [self.client requestWithMethod:@"GET" path:@"/path" parameters:nil];
    expect([request valueForHTTPHeaderField:@"x-some-key"]).to.equal(@"SomeValue");
}

- (void)testReachabilityStatus {
    [Expecta setAsynchronousTestTimeout:5.0];
    
    expect(self.client.networkReachabilityStatus).to.equal(@(AFNetworkReachabilityStatusUnknown));
    
    __block AFNetworkReachabilityStatus reachabilityStatus = self.client.networkReachabilityStatus;
    
    [self.client setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        reachabilityStatus = status;
    }];
    
    expect(reachabilityStatus).will.equal(@(AFNetworkReachabilityStatusReachableViaWiFi));
}

- (void)testJSONRequestOperationContruction {
    NSMutableURLRequest *request = [self.client requestWithMethod:@"GET" path:@"/path" parameters:nil];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    AFHTTPRequestOperation *operation = [self.client HTTPRequestOperationWithRequest:request success:NULL failure:NULL];
    expect([operation class]).to.equal([AFHTTPRequestOperation class]);
    
    expect([AFJSONRequestOperation canProcessRequest:request]).to.beTruthy();
    [self.client registerHTTPOperationClass:[AFJSONRequestOperation class]];
    operation = [self.client HTTPRequestOperationWithRequest:request success:NULL failure:NULL];
    expect([operation class]).to.equal([AFJSONRequestOperation class]);
    
    [self.client unregisterHTTPOperationClass:[AFJSONRequestOperation class]];
    operation = [self.client HTTPRequestOperationWithRequest:request success:NULL failure:NULL];
    expect([operation class]).to.equal([AFHTTPRequestOperation class]);
}

- (void)testXMLRequestOperationContruction {
    NSMutableURLRequest *request = [self.client requestWithMethod:@"GET" path:@"/path" parameters:nil];
    [request setValue:@"application/xml" forHTTPHeaderField:@"Accept"];
    
    AFHTTPRequestOperation *operation = [self.client HTTPRequestOperationWithRequest:request success:NULL failure:NULL];
    expect([operation class]).to.equal([AFHTTPRequestOperation class]);
    
    expect([AFXMLRequestOperation canProcessRequest:request]).to.beTruthy();
    [self.client registerHTTPOperationClass:[AFXMLRequestOperation class]];
    operation = [self.client HTTPRequestOperationWithRequest:request success:NULL failure:NULL];
    expect([operation class]).to.equal([AFXMLRequestOperation class]);
}

- (void)testImageRequestOperationContruction {
    NSMutableURLRequest *request = [self.client requestWithMethod:@"GET" path:@"/path" parameters:nil];
    [request setValue:@"image/png" forHTTPHeaderField:@"Accept"];
    
    AFHTTPRequestOperation *operation = [self.client HTTPRequestOperationWithRequest:request success:NULL failure:NULL];
    expect([operation class]).to.equal([AFHTTPRequestOperation class]);
    
    expect([AFImageRequestOperation canProcessRequest:request]).to.beTruthy();
    [self.client registerHTTPOperationClass:[AFImageRequestOperation class]];
    operation = [self.client HTTPRequestOperationWithRequest:request success:NULL failure:NULL];
    expect([operation class]).to.equal([AFImageRequestOperation class]);
}

- (void)testEnqueueBatchOfHTTPRequestOperations {
    [Expecta setAsynchronousTestTimeout:5.0];
    
    __block NSDate *firstCallbackTime = nil;
    __block NSDate *batchCallbackTime = nil;
    
    NSMutableURLRequest *request = [self.client requestWithMethod:@"GET" path:@"/" parameters:nil];
    AFHTTPRequestOperation *firstOperation = [self.client HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        firstCallbackTime = [NSDate date];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        firstCallbackTime = [NSDate date];
    }];
    
    AFHTTPRequestOperation *secondOperation = [self.client HTTPRequestOperationWithRequest:request success:NULL failure:NULL];
    
    [self.client enqueueBatchOfHTTPRequestOperations:@[ firstOperation, secondOperation ] progressBlock:NULL completionBlock:^(NSArray *operations) {
        batchCallbackTime = [NSDate date];
    }];
    
    expect(self.client.operationQueue.operationCount).to.equal(@3);
    expect(firstCallbackTime).willNot.beNil();
    expect(batchCallbackTime).willNot.beNil();
    
    expect(batchCallbackTime).beGreaterThan(firstCallbackTime);
}

- (void)testEnqueueBatchOfHTTPRequestOperationsWithRequests {
    [Expecta setAsynchronousTestTimeout:5.0];
    
    [self.client registerHTTPOperationClass:[AFJSONRequestOperation class]];
    [self.client registerHTTPOperationClass:[AFImageRequestOperation class]];
    
    __block NSArray *batchOperations = nil;
    
    NSMutableURLRequest *firstRequest = [self.client requestWithMethod:@"GET" path:@"/" parameters:nil];
    [firstRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    NSMutableURLRequest *secondeRequest = [self.client requestWithMethod:@"GET" path:@"/" parameters:nil];
    [secondeRequest setValue:@"image/png" forHTTPHeaderField:@"Accept"];
    
    [self.client enqueueBatchOfHTTPRequestOperationsWithRequests:@[ firstRequest, secondeRequest ] progressBlock:^(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations) {
        
    } completionBlock:^(NSArray *operations) {
        batchOperations = operations;
    }];
    
    expect(self.client.operationQueue.operationCount).to.equal(@3);
    expect(batchOperations).willNot.beNil();
    
    expect(self.client.operationQueue.operationCount).to.equal(@0);
    expect(batchOperations.count).to.equal(@2);
    
    expect([[batchOperations objectAtIndex:0] class]).to.equal([AFJSONRequestOperation class]);
    expect([[batchOperations objectAtIndex:1] class]).to.equal([AFImageRequestOperation class]);
}

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
