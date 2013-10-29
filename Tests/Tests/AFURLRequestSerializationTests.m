//
//  AFURLRequestSerializationTests.m
//  AFNetworking Tests
//
//  Created by Travis Jeffery on 10/28/13.
//  Copyright (c) 2013 AFNetworking. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AFNetworking/AFURLRequestSerialization.h>

@interface AFURLRequestSerializationTests : XCTestCase

@end

@implementation AFURLRequestSerializationTests

- (void)testThatJSONRequestSerializerReturnsRequestWithJSONContentType {
    NSURLRequest *request = [[AFJSONRequestSerializer serializer] requestWithMethod:@"GET" URLString:@"http://google.com" parameters:nil];
    NSString *contentType = [request valueForHTTPHeaderField:@"Content-Type"];
    
    XCTAssert([contentType hasPrefix:@"application/json"], @"Error Content-Type should be application/json but was: %@", contentType);
}

@end
