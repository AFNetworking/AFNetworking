//
//  AFTestCase.m
//  AFNetworking Tests
//
//  Created by Kevin Harwood on 9/10/13.
//  Copyright (c) 2013 AFNetworking. All rights reserved.
//

#import "AFTestCase.h"

NSString * const AFNetworkingTestsBaseURLString = @"https://httpbin.org/";

@implementation AFTestCase

-(NSURL*)baseURL{
    return [NSURL URLWithString:AFNetworkingTestsBaseURLString];
}
- (void)setUp
{
    [super setUp];
    [Expecta setAsynchronousTestTimeout:5.0];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

@end
