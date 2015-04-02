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
    
    //don't use the shared manager because it retains state between tests
    //but recreate it each time
    struct sockaddr_in address;
    bzero(&address, sizeof(address));
    address.sin_len = sizeof(address);
    address.sin_family = AF_INET;
    self.addressReachability = [AFNetworkReachabilityManager managerForAddress:&address];
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

- (void)testAddressReachabilityNotification {
    [self expectationForNotification:AFNetworkingReachabilityDidChangeNotification
                              object:nil
                             handler:^BOOL(NSNotification *note) {
                                 AFNetworkReachabilityStatus status;
                                 status = [note.userInfo[AFNetworkingReachabilityNotificationStatusItem] integerValue];
                                 BOOL reachable = (status == AFNetworkReachabilityStatusReachableViaWiFi
                                                   || status == AFNetworkReachabilityStatusReachableViaWWAN);
                                 
                                 XCTAssert(reachable,
                                           @"Expected network to be reachable but got '%@'",
                                           AFStringFromNetworkReachabilityStatus(status));
                                 
                                 return YES;
                             }];
    
    [self.addressReachability startMonitoring];
    
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testDomainReachabilityNotification {
    //domain-based reachability gets called back 2 times after `startMonitoring` is called
    __block NSInteger count = 0;
    [self expectationForNotification:AFNetworkingReachabilityDidChangeNotification
                              object:nil
                             handler:^BOOL(NSNotification *note) {
                                 AFNetworkReachabilityStatus status;
                                 status = [note.userInfo[AFNetworkingReachabilityNotificationStatusItem] integerValue];
                                 BOOL reachable = (status == AFNetworkReachabilityStatusReachableViaWiFi
                                                   || status == AFNetworkReachabilityStatusReachableViaWWAN);
                                 
                                 XCTAssert(reachable,
                                           @"Expected network to be reachable but got '%@'",
                                           AFStringFromNetworkReachabilityStatus(status));
                                 
                                 count++;
                                 
                                 return (count == 2);
                             }];
    
    [self.domainReachability startMonitoring];
    
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testAddressReachabilityBlock {
    XCTestExpectation *expectation = [self expectationWithDescription:@"reachability status change block gets called"];
    [self.addressReachability setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        BOOL reachable = (status == AFNetworkReachabilityStatusReachableViaWiFi
                          || status == AFNetworkReachabilityStatusReachableViaWWAN);
        
        XCTAssert(reachable, @"Expected network to be reachable but got '%@'", AFStringFromNetworkReachabilityStatus(status));
        XCTAssertEqual(reachable, self.addressReachability.isReachable, @"Expected status to match 'isReachable'");
        
        [expectation fulfill];
    }];
    
    [self.addressReachability startMonitoring];
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
        [self.addressReachability setReachabilityStatusChangeBlock:nil];
    }];
}

- (void)testDomainReachabilityBlock {
    //domain-based reachability gets called back 2 times after `startMonitoring` is called
    __block NSInteger count = 0;
    XCTestExpectation *expectation = [self expectationWithDescription:@"reachability status change block gets called"];
    [self.domainReachability setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        BOOL reachable = (status == AFNetworkReachabilityStatusReachableViaWiFi
                          || status == AFNetworkReachabilityStatusReachableViaWWAN);
        
        XCTAssert(reachable, @"Expected network to be reachable but got '%@'", AFStringFromNetworkReachabilityStatus(status));
        XCTAssertEqual(reachable, self.domainReachability.isReachable, @"Expected status to match 'isReachable'");
        
        count++;
        if (count == 2) {
            [expectation fulfill];
        }
    }];
    
    [self.domainReachability startMonitoring];
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
        [self.domainReachability setReachabilityStatusChangeBlock:nil];
    }];
}

@end
