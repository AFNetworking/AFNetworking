// AFUIActivityIndicatorViewTests.h
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
#import "UIActivityIndicatorView+AFNetworking.h"
#import "AFURLSessionManager.h"

@interface AFUIActivityIndicatorViewTests : AFTestCase
@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, strong) AFURLSessionManager *sessionManager;
@end

@implementation AFUIActivityIndicatorViewTests

- (void)setUp {
    [super setUp];
#if TARGET_OS_MACCATALYST
    self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
#else
    self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
#endif
    self.request = [NSURLRequest requestWithURL:self.delayURL];
    self.sessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:nil];
}

- (void)tearDown {
    [super tearDown];
    [self.sessionManager invalidateSessionCancelingTasks:YES resetSession:NO];
    self.sessionManager = nil;
}

- (void)testTaskDidResumeNotificationDoesNotCauseCrashForAIVWithTask {
    XCTestExpectation *expectation = [self expectationWithDescription:@"No Crash"];
    [self expectationForNotification:AFNetworkingTaskDidResumeNotification object:nil handler:nil];
    NSURLSessionDataTask *task = [self.sessionManager
                                  dataTaskWithRequest:self.request
                                  uploadProgress:nil
                                  downloadProgress:nil
                                  completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
                                      [expectation fulfill];
                                  }];
    
    [self.activityIndicatorView setAnimatingWithStateOfTask:task];
    self.activityIndicatorView = nil;
    
    [task resume];
    [self waitForExpectationsWithCommonTimeout];
    [task cancel];
}


- (void)testTaskDidCompleteNotificationDoesNotCauseCrashForAIVWithTask {
    XCTestExpectation *expectation = [self expectationWithDescription:@"No Crash"];
    [self expectationForNotification:AFNetworkingTaskDidCompleteNotification object:nil handler:nil];
    NSURLSessionDataTask *task = [self.sessionManager
                                  dataTaskWithRequest:self.request
                                  uploadProgress:nil
                                  downloadProgress:nil
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
    [self waitForExpectationsWithCommonTimeout];
    [task cancel];
}

- (void)testTaskDidSuspendNotificationDoesNotCauseCrashForAIVWithTask {
    XCTestExpectation *expectation = [self expectationWithDescription:@"No Crash"];
    [self expectationForNotification:AFNetworkingTaskDidSuspendNotification object:nil handler:nil];
    NSURLSessionDataTask *task = [self.sessionManager
                                  dataTaskWithRequest:self.request
                                  uploadProgress:nil
                                  downloadProgress:nil
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
    [self waitForExpectationsWithCommonTimeout];
    [task cancel];
}

@end
