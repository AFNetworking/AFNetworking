//
//  AFNetworkingTests.m
//  AFNetworking
//
//  Created by Blake Watters on 5/10/13.
//  Copyright (c) 2013 AFNetworking. All rights reserved.
//

NSString *AFNetworkingTestsBaseURLString = @"http://httpbin.org/";

NSURL *AFNetworkingTestsBaseURL(void)
{
    return [NSURL URLWithString:AFNetworkingTestsBaseURLString];
}
