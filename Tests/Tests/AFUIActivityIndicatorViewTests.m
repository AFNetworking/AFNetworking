// AFNetworkReachabilityManagerTests.h
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
#import <AFNetworking/UIActivityIndicatorView+AFNetworking.h>
#import <AFNetworking/AFURLSessionManager.h>
#import <AFNetworking/AFHTTPRequestOperationManager.h>

@interface AFUIActivityIndicatorViewTests : AFTestCase
@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, strong) AFURLSessionManager *sessionManager;
@property (nonatomic, strong) AFHTTPRequestOperationManager *operationManager;
@end

@implementation AFUIActivityIndicatorViewTests

- (void)setUp {
    [super setUp];
    self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.request = [NSURLRequest requestWithURL:[self.baseURL URLByAppendingPathComponent:@"delay/1"]];
    self.sessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:nil];
    self.operationManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:self.baseURL];
}

- (void)tearDown {
    [super tearDown];
    [self.sessionManager invalidateSessionCancelingTasks:YES];
    self.sessionManager = nil;
}

- (void)testTaskDidResumeNotificationDoesNotCauseCrashForAIVWithTask {
    XCTestExpectation *expectation = [self expectationWithDescription:@"No Crash"];
    [self expectationForNotification:AFNetworkingTaskDidResumeNotification object:nil handler:nil];
    NSURLSessionDataTask *task = [self.sessionManager
                                  dataTaskWithRequest:self.request
                                  completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
                                      [expectation fulfill];
                                  }];
    
    [self.activityIndicatorView setAnimatingWithStateOfTask:task];
    self.activityIndicatorView = nil;
    
    [task resume];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    [task cancel];
}

- (void)testTaskDidCompleteNotificationDoesNotCauseCrashForAIVWithTask {
    XCTestExpectation *expectation = [self expectationWithDescription:@"No Crash"];
    [self expectationForNotification:AFNetworkingTaskDidCompleteNotification object:nil handler:nil];
    NSURLSessionDataTask *task = [self.sessionManager
                                  dataTaskWithRequest:self.request
                                  completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
                                      //Without the dispatch after, this test would PASS errorenously because the test
                                      //would finish before the notification was posted to all objects that were
                                      //observing it.
                                      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                          [expectation fulfill];
                                      });
                                  }];
    
    [self.activityIndicatorView setAnimatingWithStateOfTask:task];
    self.activityIndicatorView = nil;
    
    [task resume];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    [task cancel];
}

- (void)testTaskDidSuspendNotificationDoesNotCauseCrashForAIVWithTask {
    XCTestExpectation *expectation = [self expectationWithDescription:@"No Crash"];
    [self expectationForNotification:AFNetworkingTaskDidSuspendNotification object:nil handler:nil];
    NSURLSessionDataTask *task = [self.sessionManager
                                  dataTaskWithRequest:self.request
                                  completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
                                      //Without the dispatch after, this test would PASS errorenously because the test
                                      //would finish before the notification was posted to all objects that were
                                      //observing it.
                                      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                          [expectation fulfill];
                                      });
                                  }];
    
    [self.activityIndicatorView setAnimatingWithStateOfTask:task];
    self.activityIndicatorView = nil;
    
    [task resume];
    [task suspend];
    [task resume];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    [task cancel];
}

- (void)testOperationDidStartNotificationDoesNotCauseCrashForAIVWithOperation {
    XCTestExpectation *expectation = [self expectationWithDescription:@"No Crash"];
    [self expectationForNotification:AFNetworkingOperationDidStartNotification object:nil handler:nil];
    AFHTTPRequestOperation *operation = [self.operationManager
                                         HTTPRequestOperationWithRequest:self.request
                                         success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                             [expectation fulfill];
                                         } failure:nil];
    [self.activityIndicatorView setAnimatingWithStateOfOperation:operation];
    self.activityIndicatorView = nil;
    [operation start];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    [operation cancel];
}

- (void)testOperationDidFinishNotificationDoesNotCauseCrashForAIVWithOperation {
    XCTestExpectation *expectation = [self expectationWithDescription:@"No Crash"];
    [self expectationForNotification:AFNetworkingOperationDidFinishNotification object:nil handler:nil];
    AFHTTPRequestOperation *operation = [self.operationManager
                                         HTTPRequestOperationWithRequest:self.request
                                         success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                             //Without the dispatch after, this test would PASS errorenously because the test
                                             //would finish before the notification was posted to all objects that were
                                             //observing it.
                                             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                                  [expectation fulfill];
                                             });

                                         } failure:nil];
    [self.activityIndicatorView setAnimatingWithStateOfOperation:operation];
    self.activityIndicatorView = nil;
    [operation start];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    [operation cancel];
}

// Tests issue #2739. -[UIActivityIndicatorView dealloc] removes an observer and clobbering it in a category creates a zombie reference.
- (void)testBackgroundingDoesNotCauseCrashWithOperation {
    XCTestExpectation *expectation = [self expectationWithDescription:@"No Crash"];
    AFHTTPRequestOperation *operation = [self.operationManager
                                         HTTPRequestOperationWithRequest:self.request
                                         success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                         } failure:nil];
    [self.activityIndicatorView setAnimatingWithStateOfOperation:operation];
    self.activityIndicatorView = nil;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end