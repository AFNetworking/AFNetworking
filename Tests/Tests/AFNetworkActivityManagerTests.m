// AFNetworkActivityManagerTests.m
// Copyright (c) 2011–2015 Alamofire Software Foundation (http://alamofire.org/)
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

#import "AFTestCase.h"

#import "AFNetworkActivityIndicatorManager.h"
#import "AFHTTPSessionManager.h"

@interface AFNetworkActivityManagerTests : AFTestCase
@property (nonatomic, strong) AFNetworkActivityIndicatorManager *networkActivityIndicatorManager;
@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;
@end

#pragma mark -

@implementation AFNetworkActivityManagerTests

- (void)setUp {
    [super setUp];

    self.sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:self.baseURL sessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];

    self.networkActivityIndicatorManager = [[AFNetworkActivityIndicatorManager alloc] init];
    self.networkActivityIndicatorManager.enabled = YES;
}

- (void)tearDown {
    [super tearDown];
    self.networkActivityIndicatorManager = nil;

    [self.sessionManager invalidateSessionCancelingTasks:YES];
}

#pragma mark -

- (void)testThatNetworkActivityIndicatorTurnsOffIndicatorWhenRequestSucceeds {
    XCTestExpectation *requestCompleteExpectation = [self expectationWithDescription:@"Request should succeed"];
    [self.sessionManager
     GET:@"/delay/1"
     parameters:nil
     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
         [requestCompleteExpectation fulfill];
     }
     failure:nil];
    [self expectationForPredicate:[NSPredicate predicateWithFormat:@"isNetworkActivityIndicatorVisible == YES"]
                                               evaluatedWithObject:self.networkActivityIndicatorManager
                                                           handler:nil];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];

    [self expectationForPredicate:[NSPredicate predicateWithFormat:@"isNetworkActivityIndicatorVisible == NO"]
              evaluatedWithObject:self.networkActivityIndicatorManager
                          handler:nil];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testThatNetworkActivityIndicatorTurnsOffIndicatorWhenRequestFails {
    XCTestExpectation *requestCompleteExpectation = [self expectationWithDescription:@"Request should succeed"];
    [self.sessionManager
     GET:@"/status/500"
     parameters:nil
     success:nil
     failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
         [requestCompleteExpectation fulfill];
     }];

    [self
     keyValueObservingExpectationForObject:self.networkActivityIndicatorManager
     keyPath:@"isNetworkActivityIndicatorVisible"
     handler:^BOOL(AFNetworkActivityIndicatorManager * observedObject, NSDictionary * _Nonnull change) {
         return observedObject.isNetworkActivityIndicatorVisible;
     }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];

    [self expectationForPredicate:[NSPredicate predicateWithFormat:@"isNetworkActivityIndicatorVisible == NO"]
              evaluatedWithObject:self.networkActivityIndicatorManager
                          handler:nil];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end
