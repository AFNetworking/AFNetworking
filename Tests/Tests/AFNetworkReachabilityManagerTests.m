// AFNetworkReachabilityManagerTests.h
//
// Copyright (c) 2013-2015 AFNetworking (http://afnetworking.com)
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

#import "AFNetworkReachabilityManager.h"

@interface AFNetworkReachabilityManagerTests : AFTestCase
@property (nonatomic, strong) AFNetworkReachabilityManager *networkReachability;
@property (nonatomic, strong) AFNetworkReachabilityManager *localhostReachability;
@end

@implementation AFNetworkReachabilityManagerTests

- (void)setUp {
    [super setUp];
    
    //both of these manager objects should always be reachable when the tests are run
    self.networkReachability = [AFNetworkReachabilityManager sharedManager];
    self.localhostReachability = [AFNetworkReachabilityManager managerForDomain:@"localhost"];
}

- (void)testNetworkReachabilityStartsInUnknownState {
    XCTAssertEqual(self.networkReachability.networkReachabilityStatus, AFNetworkReachabilityStatusUnknown,
                   @"Reachability should start in an unknown state");
}

- (void)testLocalhostReachabilityStartsInUnknownState {
    XCTAssertEqual(self.localhostReachability.networkReachabilityStatus, AFNetworkReachabilityStatusUnknown,
                   @"Reachability should start in an unknown state");
}

- (void)verifyReachabilityNotificationWithManager:(AFNetworkReachabilityManager *)reachability {
    [self
     expectationForNotification:AFNetworkingReachabilityDidChangeNotification
                              object:nil
                             handler:^BOOL(NSNotification *notification) {
                                 AFNetworkReachabilityStatus status;
                                 status = [notification.userInfo[AFNetworkingReachabilityNotificationStatusItem] integerValue];
                                 XCTAssert(reachability.isReachable,
                                           @"Expected network to be reachable but got '%@'",
                                           AFStringFromNetworkReachabilityStatus(status));
                                 
                                 return YES;
                             }];
    
    [reachability startMonitoring];
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testNetworkReachabilityNotification {
    [self verifyReachabilityNotificationWithManager:self.networkReachability];
}

- (void)testLocalhostReachabilityNotification {
    [self verifyReachabilityNotificationWithManager:self.localhostReachability];
}

//- (void)testNetworkReachability {
//    XCTAssertFalse(reachability.isReachable);
//
//    [self expectationForNotification:AFNetworkingReachabilityDidChangeNotification
//                              object:nil
//                             handler:^BOOL(NSNotification *notification) {
//                                 AFNetworkReachabilityStatus status;
//                                 status = [notification.userInfo[AFNetworkingReachabilityNotificationStatusItem] integerValue];
//                                 NSLog(@"%@", AFStringFromNetworkReachabilityStatus(status));
//                                 
//                                 XCTAssert(reachability.isReachable);
//                                
//                                 return YES;
//                             }];
//    
//    XCTestExpectation *expectation = [self expectationWithDescription:@""];
//    
//    [reachability setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
//        NSLog(@"%@", AFStringFromNetworkReachabilityStatus(status));
//        
//        BOOL reachable = (status == AFNetworkReachabilityStatusReachableViaWiFi
//                          || status == AFNetworkReachabilityStatusReachableViaWWAN);
//        XCTAssert(reachable);
//        [expectation fulfill];
//    }];
//    
//    [reachability startMonitoring];
//    
//    [self waitForExpectationsWithTimeout:10 handler:nil];
//}

@end
