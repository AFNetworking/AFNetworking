//
//  AFURLSessionAvailabilityTests.m
//  AFNetworking Tests
//
//  Created by Brian Gerstle on 3/31/15.
//  Copyright (c) 2015 AFNetworking. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AFTestCase.h"
#import <AFNetworking/AFURLSessionManager.h>

@interface AFURLSessionAvailabilityTests : AFTestCase

@end

@implementation AFURLSessionAvailabilityTests

- (void)testAvailability {
    expect([AFURLSessionManager isAvailable]).to.equal([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0);
}

@end
