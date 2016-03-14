// AFNetworkReachabilityManagerTests.h
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

#import "AFNetworkReachabilityManager.h"
#import <netinet/in.h>

@interface AFNetworkReachabilityManagerTests : AFTestCase
@property (nonatomic, strong) AFNetworkReachabilityManager *addressReachability;
@property (nonatomic, strong) AFNetworkReachabilityManager *domainReachability;
@end

@implementation AFNetworkReachabilityManagerTests

- (void)setUp {
    [super setUp];

    //both of these manager objects should always be reachable when the tests are run
    self.domainReachability = [AFNetworkReachabilityManager managerForDomain:@"localhost"];
    self.addressReachability = [AFNetworkReachabilityManager manager];
}

- (void)tearDown
{
    [self.addressReachability stopMonitoring];
    [self.domainReachability stopMonitoring];

    [super tearDown];
}

- (void)testAddressReachabilityStartsInUnknownState {
    XCTAssertEqual(self.addressReachability.networkReachabilityStatus, AFNetworkReachabilityStatusUnknown,
                   @"Reachability should start in an unknown state");
}

- (void)testDomainReachabilityStartsInUnknownState {
    XCTAssertEqual(self.domainReachability.networkReachabilityStatus, AFNetworkReachabilityStatusUnknown,
                   @"Reachability should start in an unknown state");
}

- (void)verifyReachabilityNotificationGetsPostedWithManager:(AFNetworkReachabilityManager *)manager
{
    [self expectationForNotification:AFNetworkingReachabilityDidChangeNotification
                              object:nil
                             handler:^BOOL(NSNotification *note) {
                                 AFNetworkReachabilityStatus status;
                                 status = [note.userInfo[AFNetworkingReachabilityNotificationStatusItem] integerValue];
                                 BOOL reachable = (status == AFNetworkReachabilityStatusReachableViaWiFi
                                                   || status == AFNetworkReachabilityStatusReachableViaWWAN);

                                 if (reachable) {
                                     XCTAssert(reachable,
                                               @"Expected network to be reachable but got '%@'",
                                               AFStringFromNetworkReachabilityStatus(status));
                                     XCTAssertEqual(reachable, manager.isReachable, @"Expected status to match 'isReachable'");
                                 }

                                 return reachable;
                             }];

    [manager startMonitoring];

    [self waitForExpectationsWithCommonTimeoutUsingHandler:nil];
}

- (void)testAddressReachabilityNotification {
    [self verifyReachabilityNotificationGetsPostedWithManager:self.addressReachability];
}

//Commenting out for Travis Stability
//- (void)testDomainReachabilityNotification {
//    [self verifyReachabilityNotificationGetsPostedWithManager:self.domainReachability];
//}

- (void)verifyReachabilityStatusBlockGetsCalledWithManager:(AFNetworkReachabilityManager *)manager
{
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"reachability status change block gets called"];

    typeof(manager) __weak weakManager = manager;
    [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        BOOL reachable = (status == AFNetworkReachabilityStatusReachableViaWiFi
                          || status == AFNetworkReachabilityStatusReachableViaWWAN);

        XCTAssert(reachable, @"Expected network to be reachable but got '%@'", AFStringFromNetworkReachabilityStatus(status));
        XCTAssertEqual(reachable, weakManager.isReachable, @"Expected status to match 'isReachable'");

        [expectation fulfill];
    }];

    [manager startMonitoring];

    [self waitForExpectationsWithCommonTimeoutUsingHandler:nil];
    [manager setReachabilityStatusChangeBlock:nil];
    
}

- (void)testAddressReachabilityBlock {
    [self verifyReachabilityStatusBlockGetsCalledWithManager:self.addressReachability];
}

- (void)testDomainReachabilityBlock {
    [self verifyReachabilityStatusBlockGetsCalledWithManager:self.domainReachability];
}

@end
