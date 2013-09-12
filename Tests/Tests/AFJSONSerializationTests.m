//
//  AFJSONSerializationTests.m
//  AFNetworking Tests
//
//  Created by Kevin Harwood on 9/10/13.
//  Copyright (c) 2013 AFNetworking. All rights reserved.
//

#import "AFTestCase.h"

@interface AFJSONSerializationTests : AFTestCase

@end

@implementation AFJSONSerializationTests

-(NSData*)dummyJSONData{
    NSDictionary * jsonDict = @{@"dummy":@{@"key":@"value"}};
    return [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:nil];
}

#pragma mark - JSON Response Serializer Tests

- (void)testThatJSONResponseSerializerAcceptsApplicationJSONMimeType {
    NSHTTPURLResponse * response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL
                                                               statusCode:200
                                                              HTTPVersion:@"1.1"
                                                             headerFields:@{@"Content-Type":@"application/json"}];
    

    AFJSONResponseSerializer * serializer = [AFJSONResponseSerializer serializer];
    NSError * error = nil;
    [serializer validateResponse:response
                            data:[self dummyJSONData]
                           error:&error];
    XCTAssertNil(error, @"Error handling application/json");
}

- (void)testThatJSONResponseSerializerAcceptsTextJSONMimeType {
    NSHTTPURLResponse * response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL
                                                               statusCode:200
                                                              HTTPVersion:@"1.1"
                                                             headerFields:@{@"Content-Type":@"text/json"}];
    
    
    AFJSONResponseSerializer * serializer = [AFJSONResponseSerializer serializer];
    NSError * error = nil;
    [serializer validateResponse:response
                            data:[self dummyJSONData]
                           error:&error];
    XCTAssertNil(error, @"Error handling text/json");
}

- (void)testThatJSONResponseSerializerAcceptsTextJavaScriptMimeType {
    NSHTTPURLResponse * response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL
                                                               statusCode:200
                                                              HTTPVersion:@"1.1"
                                                             headerFields:@{@"Content-Type":@"text/javascript"}];
    
    
    AFJSONResponseSerializer * serializer = [AFJSONResponseSerializer serializer];
    NSError * error = nil;
    [serializer validateResponse:response
                            data:[self dummyJSONData]
                           error:&error];
    XCTAssertNil(error, @"Error handling text/javascript");
}

- (void)testThatJSONResponseSerializerDoesNotAcceptNonStandardJSONMimeType {
    NSHTTPURLResponse * response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL
                                                               statusCode:200
                                                              HTTPVersion:@"1.1"
                                                             headerFields:@{@"Content-Type":@"nonstandard/json"}];
    
    
    AFJSONResponseSerializer * serializer = [AFJSONResponseSerializer serializer];
    NSError * error = nil;
    [serializer validateResponse:response
                            data:[self dummyJSONData]
                           error:&error];
    XCTAssertNotNil(error, @"Error should have been thrown for nonstandard/json");
}

- (void)testThatJSONResponseSerializerReturnsDictionaryForValidJSONDictionary{
    AFJSONResponseSerializer * serializer = [AFJSONResponseSerializer serializer];
    NSHTTPURLResponse * response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL
                                                               statusCode:200
                                                              HTTPVersion:@"1.1"
                                                             headerFields:@{@"Content-Type":@"text/json"}];
    NSError * error = nil;
    id responseObject = [serializer responseObjectForResponse:response
                                                         data:[self dummyJSONData]
                                                        error:&error];
    XCTAssertNil(error, @"Serialization error should be nil");
    XCTAssert([responseObject isKindOfClass:[NSDictionary class]], @"Expected response to be a NSDictionary");
}

- (void)testThatJSONResponseSerializerReturnsErrorForInvalidJSON{
    AFJSONResponseSerializer * serializer = [AFJSONResponseSerializer serializer];
    NSHTTPURLResponse * response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL
                                                               statusCode:200
                                                              HTTPVersion:@"1.1"
                                                             headerFields:@{@"Content-Type":@"text/json"}];
    NSError * error = nil;
    [serializer responseObjectForResponse:response
                                     data:[@"{invalidJSON:}" dataUsingEncoding:NSUTF8StringEncoding]
                                    error:&error];
    XCTAssertNotNil(error, @"Serialization error should not be nil");
}


@end
