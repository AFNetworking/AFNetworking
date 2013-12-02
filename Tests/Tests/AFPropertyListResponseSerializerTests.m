//
//  AFPropertyListResponseSerializerTests.m
//  AFNetworking Tests
//
//  Created by Kyle Fuller on 29/11/2013.
//  Copyright (c) 2013 AFNetworking. All rights reserved.
//

#import "AFTestCase.h"

#import "AFURLResponseSerialization.h"


@interface AFPropertyListResponseSerializerTests : AFTestCase

@end

@implementation AFPropertyListResponseSerializerTests

- (void)testThatPropertyListResponseSerializerHandles204 {
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:204 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/x-plist"}];

    id<AFURLResponseSerialization> serializer = [AFPropertyListResponseSerializer serializer];
    NSError *error;
    id responseObject = [serializer responseObjectForResponse:response data:nil error:&error];

    XCTAssertNil(responseObject, @"Response should be nil when handling 204 with application/x-plist");
    XCTAssertNil(error, @"Error handling application/x-plist");
}

@end
