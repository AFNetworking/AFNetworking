//
//  AFURLSessionDataTaskNotificationTests.m
//  AFNetworking Tests
//
//  Created by Brian Gerstle on 3/31/15.
//  Copyright (c) 2015 AFNetworking. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AFTestCase.h"
#import <AFNetworking/AFURLSessionManager.h>

/*
  This test can't be run in the application tests target due to weird issues with swizzling.
 */
@interface AFURLSessionDataTaskNotificationTests : AFTestCase
@property AFURLSessionManager* manager;
@end

@implementation AFURLSessionDataTaskNotificationTests

+ (BOOL)requiresSessionAPIAvailability {
    return YES;
}

- (void)setUpSessionTest {
    self.manager = [AFURLSessionManager new];
}

- (void)testTaskNotifications {
	NSURLSessionDataTask *task =
	    [self.manager dataTaskWithRequest:[NSURLRequest requestWithURL:self.baseURL]
	                    completionHandler:nil];
    NSParameterAssert(task);
    [self expectationForNotification:AFNetworkingTaskDidResumeNotification object:task handler:nil];
    [self expectationForNotification:AFNetworkingTaskDidSuspendNotification object:task handler:nil];
    [task resume];
    [task suspend];
    [self waitForExpectationsWithTimeout:AFNetworkingDefaultTestTimeout handler:nil];
}

@end
