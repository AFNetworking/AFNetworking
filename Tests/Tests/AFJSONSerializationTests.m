// AFJSONSerializationTests.m
//
// Copyright (c) 2013-2014 AFNetworking (http://afnetworking.com)
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

#import "AFURLRequestSerialization.h"
#import "AFURLResponseSerialization.h"

static NSData * AFJSONTestData() {
    return [NSJSONSerialization dataWithJSONObject:@{@"foo": @"bar"} options:0 error:nil];
}

#pragma mark -

@interface AFJSONSerializationTests : AFTestCase
@end

@implementation AFJSONSerializationTests

- (void)testThatJSONRequestSerializationHandlesParametersDictionary {
    NSDictionary *parameters = @{@"key":@"value"};
    NSError *error = nil;
    AFJSONRequestSerializer *serializer = [[AFJSONRequestSerializer alloc] init];
    NSMutableURLRequest *request = [serializer requestWithMethod:@"POST"
                                                       URLString:AFNetworkingTestsBaseURLString
                                                      parameters:parameters
                                                           error:&error];
    XCTAssertNil(error, @"Serialization error should be nil");
    NSString *body = [[NSString alloc] initWithData:[request HTTPBody]
                                           encoding:NSUTF8StringEncoding];
    XCTAssertTrue([@"{\"key\":\"value\"}" isEqualToString:body], @"Parameters were not encoded correctly");
}

- (void)testThatJSONRequestSerializationHandlesParametersArray {
    NSArray *parameters = @[@{@"key":@"value"}];
    NSError *error = nil;
    AFJSONRequestSerializer *serializer = [[AFJSONRequestSerializer alloc] init];
    NSMutableURLRequest *request = [serializer requestWithMethod:@"POST"
                                                       URLString:AFNetworkingTestsBaseURLString
                                                      parameters:parameters
                                                           error:&error];
    XCTAssertNil(error, @"Serialization error should be nil");
    NSString *body = [[NSString alloc] initWithData:[request HTTPBody]
                                                   encoding:NSUTF8StringEncoding];
    XCTAssertTrue([@"[{\"key\":\"value\"}]" isEqualToString:body], @"Parameters were not encoded correctly");
}

- (void)testThatJSONResponseSerializerAcceptsApplicationJSONMimeType {
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/json"}];

    AFJSONResponseSerializer *serializer = [AFJSONResponseSerializer serializer];
    NSError *error = nil;
    [serializer validateResponse:response data:AFJSONTestData() error:&error];

    XCTAssertNil(error, @"Error handling application/json");
}

- (void)testThatJSONResponseSerializerAcceptsTextJSONMimeType {
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"text/json"}];

    AFJSONResponseSerializer *serializer = [AFJSONResponseSerializer serializer];
    NSError *error = nil;
    [serializer validateResponse:response data:AFJSONTestData()error:&error];

    XCTAssertNil(error, @"Error handling text/json");
}

- (void)testThatJSONResponseSerializerAcceptsTextJavaScriptMimeType {
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"text/javascript"}];

    AFJSONResponseSerializer *serializer = [AFJSONResponseSerializer serializer];
    NSError *error = nil;
    [serializer validateResponse:response data:AFJSONTestData() error:&error];

    XCTAssertNil(error, @"Error handling text/javascript");
}

- (void)testThatJSONResponseSerializerDoesNotAcceptNonStandardJSONMimeType {
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"nonstandard/json"}];

    AFJSONResponseSerializer *serializer = [AFJSONResponseSerializer serializer];
    NSError *error = nil;
    [serializer validateResponse:response data:AFJSONTestData() error:&error];

    XCTAssertNotNil(error, @"Error should have been thrown for nonstandard/json");
}

- (void)testThatJSONResponseSerializerReturnsDictionaryForValidJSONDictionary {
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"text/json"}];

    AFJSONResponseSerializer *serializer = [AFJSONResponseSerializer serializer];
    NSError *error = nil;
    id responseObject = [serializer responseObjectForResponse:response data:AFJSONTestData() error:&error];

    XCTAssertNil(error, @"Serialization error should be nil");
    XCTAssert([responseObject isKindOfClass:[NSDictionary class]], @"Expected response to be a NSDictionary");
}

- (void)testThatJSONResponseSerializerReturnsErrorForInvalidJSON {
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type":@"text/json"}];

    AFJSONResponseSerializer *serializer = [AFJSONResponseSerializer serializer];
    NSError *error = nil;
    [serializer responseObjectForResponse:response data:[@"{invalid}" dataUsingEncoding:NSUTF8StringEncoding] error:&error];

    XCTAssertNotNil(error, @"Serialization error should not be nil");
}

@end
