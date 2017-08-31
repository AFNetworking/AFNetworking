// AFJSONSerializationTests.m
// Copyright (c) 2011–2016 Alamofire Software Foundation ( http://alamofire.org/ )
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
    return [NSJSONSerialization dataWithJSONObject:@{@"foo": @"bar"} options:(NSJSONWritingOptions)0 error:nil];
}

#pragma mark -

@interface AFJSONRequestSerializationTests : AFTestCase
@property (nonatomic, strong) AFJSONRequestSerializer *requestSerializer;
@end

@implementation AFJSONRequestSerializationTests

- (void)setUp {
    self.requestSerializer = [[AFJSONRequestSerializer alloc] init];
}

#pragma mark -

- (void)testThatJSONRequestSerializationHandlesParametersDictionary {
    NSDictionary *parameters = @{@"key":@"value"};
    NSError *error = nil;
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"POST" URLString:self.baseURL.absoluteString parameters:parameters error:&error];

    XCTAssertNil(error, @"Serialization error should be nil");

    NSString *body = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];

    XCTAssertTrue([@"{\"key\":\"value\"}" isEqualToString:body], @"Parameters were not encoded correctly");
}

- (void)testThatJSONRequestSerializationHandlesParametersArray {
    NSArray *parameters = @[@{@"key":@"value"}];
    NSError *error = nil;
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"POST" URLString:self.baseURL.absoluteString parameters:parameters error:&error];

    XCTAssertNil(error, @"Serialization error should be nil");

    NSString *body = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];

    XCTAssertTrue([@"[{\"key\":\"value\"}]" isEqualToString:body], @"Parameters were not encoded correctly");
}

- (void)testThatJSONRequestSerializationHandlesInvalidParameters {
    NSString *string = [[NSString alloc] initWithBytes:"\xd8\x00" length:2 encoding:NSUTF16StringEncoding];
    
    NSDictionary *parameters = @{@"key":string};
    NSError *error = nil;
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"POST" URLString:self.baseURL.absoluteString parameters:parameters error:&error];
    
    XCTAssertNil(request, @"Expected nil request.");
    XCTAssertNotNil(error, @"Expected non-nil error.");
}

- (void)testThatJSONRequestSerializationErrorsWithInvalidJSON {
    NSDictionary *parameters = @{@"key":[NSSet setWithObject:@"value"]};
    NSError *error = nil;
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"POST" URLString:self.baseURL.absoluteString parameters:parameters error:&error];
    
    XCTAssertNil(request, @"Request should be nil");
    XCTAssertNotNil(error, @"Serialization error should be not nil");
    XCTAssertEqualObjects(error.domain, AFURLRequestSerializationErrorDomain);
    XCTAssertEqual(error.code, NSURLErrorCannotDecodeContentData);
    XCTAssertEqualObjects(error.localizedFailureReason, @"The `parameters` argument is not valid JSON.");
}

@end

#pragma mark -

@interface AFJSONResponseSerializationTests : AFTestCase
@property (nonatomic, strong) AFJSONResponseSerializer *responseSerializer;
@end

@implementation AFJSONResponseSerializationTests

- (void)setUp {
    [super setUp];
    self.responseSerializer = [AFJSONResponseSerializer serializer];
}

#pragma mark -

- (void)testThatJSONResponseSerializerAcceptsApplicationJSONMimeType {
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/json"}];

    NSError *error = nil;
    [self.responseSerializer validateResponse:response data:AFJSONTestData() error:&error];

    XCTAssertNil(error, @"Error handling application/json");
}

- (void)testThatJSONResponseSerializerAcceptsTextJSONMimeType {
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"text/json"}];
    NSError *error = nil;
    [self.responseSerializer validateResponse:response data:AFJSONTestData()error:&error];

    XCTAssertNil(error, @"Error handling text/json");
}

- (void)testThatJSONResponseSerializerAcceptsTextJavaScriptMimeType {
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"text/javascript"}];
    NSError *error = nil;
    [self.responseSerializer validateResponse:response data:AFJSONTestData() error:&error];

    XCTAssertNil(error, @"Error handling text/javascript");
}

- (void)testThatJSONResponseSerializerDoesNotAcceptNonStandardJSONMimeType {
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"nonstandard/json"}];
    NSError *error = nil;
    [self.responseSerializer validateResponse:response data:AFJSONTestData() error:&error];

    XCTAssertNotNil(error, @"Error should have been thrown for nonstandard/json");
}

- (void)testThatJSONResponseSerializerReturnsDictionaryForValidJSONDictionary {
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"text/json"}];
    NSError *error = nil;
    id responseObject = [self.responseSerializer responseObjectForResponse:response data:AFJSONTestData() error:&error];

    XCTAssertNil(error, @"Serialization error should be nil");
    XCTAssert([responseObject isKindOfClass:[NSDictionary class]], @"Expected response to be a NSDictionary");
}

- (void)testThatJSONResponseSerializerReturnsErrorForInvalidJSON {
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type":@"text/json"}];
    NSError *error = nil;
    [self.responseSerializer responseObjectForResponse:response data:[@"{invalid}" dataUsingEncoding:NSUTF8StringEncoding] error:&error];

    XCTAssertNotNil(error, @"Serialization error should not be nil");
}

- (void)testThatJSONResponseSerializerReturnsNilObjectAndNilErrorForEmptyData {
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type":@"text/json"}];
    NSData *data = [NSData data];
    NSError *error = nil;
    id responseObject = [self.responseSerializer responseObjectForResponse:response data:data error:&error];
    XCTAssertNil(responseObject);
    XCTAssertNil(error);
}

- (void)testThatJSONResponseSerializerReturnsNilObjectAndNilErrorForSingleSpace {
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type":@"text/json"}];
    NSData *data = [@" " dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    id responseObject = [self.responseSerializer responseObjectForResponse:response data:data error:&error];
    XCTAssertNil(responseObject);
    XCTAssertNil(error);
}

- (void)testThatJSONRemovesKeysWithNullValues {
    self.responseSerializer.removesKeysWithNullValues = YES;
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type":@"text/json"}];
    NSData *data = [NSJSONSerialization dataWithJSONObject:@{@"key":@"value",@"nullkey":[NSNull null],@"array":@[@{@"subnullkey":[NSNull null]}]}
                                                   options:(NSJSONWritingOptions)0
                                                     error:nil];

    NSError *error = nil;
    NSDictionary *responseObject = [self.responseSerializer responseObjectForResponse:response
                                                                                 data:data
                                                                                error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(responseObject[@"key"]);
    XCTAssertNil(responseObject[@"nullkey"]);
    XCTAssertNil(responseObject[@"array"][0][@"subnullkey"]);
}

- (void)testThatJSONResponseSerializerCanBeCopied {
    [self.responseSerializer setAcceptableStatusCodes:[NSIndexSet indexSetWithIndex:100]];
    [self.responseSerializer setAcceptableContentTypes:[NSSet setWithObject:@"test/type"]];
    [self.responseSerializer setReadingOptions:NSJSONReadingMutableLeaves];
    [self.responseSerializer setRemovesKeysWithNullValues:YES];

    AFJSONResponseSerializer *copiedSerializer = [self.responseSerializer copy];
    XCTAssertNotEqual(copiedSerializer, self.responseSerializer);
    XCTAssertEqual(copiedSerializer.acceptableStatusCodes, self.responseSerializer.acceptableStatusCodes);
    XCTAssertEqual(copiedSerializer.acceptableContentTypes, self.responseSerializer.acceptableContentTypes);
    XCTAssertEqual(copiedSerializer.readingOptions, self.responseSerializer.readingOptions);
    XCTAssertEqual(copiedSerializer.removesKeysWithNullValues, self.responseSerializer.removesKeysWithNullValues);
}

@end
