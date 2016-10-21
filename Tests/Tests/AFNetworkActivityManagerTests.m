// AFNetworkActivityManagerTests.m
// Copyright (c) 2011–2016 Alamofire Software Foundation ( http://alamofire.org/ )
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

- (void)testThatNetworkActivityIndicatorTurnsOnAndOffIndicatorWhenRequestSucceeds {
    self.networkActivityIndicatorManager.activationDelay = 0.0;
    self.networkActivityIndicatorManager.completionDelay = 0.0;

    XCTestExpectation *startExpectation = [self expectationWithDescription:@"Indicator Visible"];
    XCTestExpectation *endExpectation = [self expectationWithDescription:@"Indicator Hidden"];
    [self.networkActivityIndicatorManager setNetworkingActivityActionWithBlock:^(BOOL networkActivityIndicatorVisible) {
        if (networkActivityIndicatorVisible) {
            [startExpectation fulfill];
        } else {
            [endExpectation fulfill];
        }
    }];

    XCTestExpectation *requestExpectation = [self expectationWithDescription:@"Request should succeed"];
    [self.sessionManager
     GET:@"/delay/1"
     parameters:nil
     progress:nil
     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
         [requestExpectation fulfill];
     }
     failure:nil];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testThatNetworkActivityIndicatorTurnsOnAndOffIndicatorWhenRequestFails {
    self.networkActivityIndicatorManager.activationDelay = 0.0;
    self.networkActivityIndicatorManager.completionDelay = 0.0;

    XCTestExpectation *startExpectation = [self expectationWithDescription:@"Indicator Visible"];
    XCTestExpectation *endExpectation = [self expectationWithDescription:@"Indicator Hidden"];
    [self.networkActivityIndicatorManager setNetworkingActivityActionWithBlock:^(BOOL networkActivityIndicatorVisible) {
        if (networkActivityIndicatorVisible) {
            [startExpectation fulfill];
        } else {
            [endExpectation fulfill];
        }
    }];

    XCTestExpectation *requestExpectation = [self expectationWithDescription:@"Request should fail"];
    [self.sessionManager
     GET:@"/status/404"
     parameters:nil
     progress:nil
     success:nil
     failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
         [requestExpectation fulfill];
     }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testThatVisibilityDelaysAreApplied {

    self.networkActivityIndicatorManager.activationDelay = 1.0;
    self.networkActivityIndicatorManager.completionDelay = 1.0;

    CFTimeInterval requestStartTime = CACurrentMediaTime();
    __block CFTimeInterval requestEndTime;
    __block CFTimeInterval indicatorVisbleTime;
    __block CFTimeInterval indicatorHiddenTime;
    XCTestExpectation *startExpectation = [self expectationWithDescription:@"Indicator Visible"];
    XCTestExpectation *endExpectation = [self expectationWithDescription:@"Indicator Hidden"];
    [self.networkActivityIndicatorManager setNetworkingActivityActionWithBlock:^(BOOL networkActivityIndicatorVisible) {
        if (networkActivityIndicatorVisible) {
             indicatorVisbleTime = CACurrentMediaTime();
            [startExpectation fulfill];
        } else {
            indicatorHiddenTime = CACurrentMediaTime();
            [endExpectation fulfill];
        }
    }];

    XCTestExpectation *requestExpectation = [self expectationWithDescription:@"Request should succeed"];
    [self.sessionManager
     GET:@"/delay/2"
     parameters:nil
     progress:nil
     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
         requestEndTime = CACurrentMediaTime();
         [requestExpectation fulfill];
     }
     failure:nil];
    [self waitForExpectationsWithCommonTimeout];
    XCTAssertTrue((indicatorVisbleTime - requestStartTime) > self.networkActivityIndicatorManager.activationDelay);
    XCTAssertTrue((indicatorHiddenTime - requestEndTime) > self.networkActivityIndicatorManager.completionDelay);
}

- (void)testThatIndicatorBlockIsOnlyCalledOnceEachForStartAndEndForMultipleRequests {
    self.networkActivityIndicatorManager.activationDelay = 1.0;
    self.networkActivityIndicatorManager.completionDelay = 1.0;

    XCTestExpectation *startExpectation = [self expectationWithDescription:@"Indicator Visible"];
    XCTestExpectation *endExpectation = [self expectationWithDescription:@"Indicator Hidden"];
    [self.networkActivityIndicatorManager setNetworkingActivityActionWithBlock:^(BOOL networkActivityIndicatorVisible) {
        if (networkActivityIndicatorVisible) {
            [startExpectation fulfill];
        } else {
            [endExpectation fulfill];
        }
    }];

    XCTestExpectation *requestExpectation = [self expectationWithDescription:@"Request should succeed"];
    [self.sessionManager
     GET:@"/delay/4"
     parameters:nil
     progress:nil
     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
         [requestExpectation fulfill];
     }
     failure:nil];

    XCTestExpectation *secondRequestExpectation = [self expectationWithDescription:@"Request should succeed"];
    [self.sessionManager
     GET:@"/delay/2"
     parameters:nil
     progress:nil
     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {

         [secondRequestExpectation fulfill];
     }
     failure:nil];

    [self waitForExpectationsWithCommonTimeout];

}

@end
