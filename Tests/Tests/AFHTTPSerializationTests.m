//
//  AFHTTPSerializationTests.m
//  AFNetworking Tests
//
//  Created by Kevin Harwood on 9/10/13.
//  Copyright (c) 2013 AFNetworking. All rights reserved.
//

#import "AFTestCase.h"

@interface AFHTTPSerializationTests : AFTestCase

@end

@implementation AFHTTPSerializationTests

-(void)testThatAFHTTPResponseSerializationHandlesAll2XXCodes{
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
    [indexSet
     enumerateIndexesUsingBlock:^(NSUInteger statusCode, BOOL *stop) {
         NSHTTPURLResponse * response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL
                                                                    statusCode:statusCode
                                                                   HTTPVersion:@"1.1"
                                                                  headerFields:@{@"Content-Type":@"text/html"}];
         AFHTTPResponseSerializer * serializer = [AFHTTPResponseSerializer serializer];
         NSError * error = nil;
         [serializer validateResponse:response
                                 data:[@"text" dataUsingEncoding:NSUTF8StringEncoding]
                                error:&error];
         XCTAssertNil(error, @"Error handling status code %d",statusCode);
     }];
}

-(void)testThatAFHTTPResponseSerializationFailsAll4XX5XXStatusCodes{
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(400, 200)];
    [indexSet
     enumerateIndexesUsingBlock:^(NSUInteger statusCode, BOOL *stop) {
         NSHTTPURLResponse * response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL
                                                                    statusCode:statusCode
                                                                   HTTPVersion:@"1.1"
                                                                  headerFields:@{@"Content-Type":@"text/html"}];
         AFHTTPResponseSerializer * serializer = [AFHTTPResponseSerializer serializer];
         NSError * error = nil;
         [serializer validateResponse:response
                                 data:[@"text" dataUsingEncoding:NSUTF8StringEncoding]
                                error:&error];
         XCTAssertNotNil(error, @"Did not fail handling status code %d",statusCode);
     }];
}

@end
