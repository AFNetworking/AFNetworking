// AFHTTPResponseSerializationTests.m
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

#import "AFURLResponseSerialization.h"

@interface AFHTTPResponseSerializationTests : AFTestCase
@property (nonatomic, strong) AFHTTPResponseSerializer *responseSerializer;
@end

@implementation AFHTTPResponseSerializationTests

- (void)setUp {
    [super setUp];
    self.responseSerializer = [AFHTTPResponseSerializer serializer];
}

#pragma mark - validateResponse tests

- (void)testThatAFHTTPResponseSerializationHandlesAll2XXCodes {
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger statusCode, BOOL *stop) {
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:statusCode HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"text/html"}];

        XCTAssert([self.responseSerializer.acceptableStatusCodes containsIndex:statusCode], @"Status code %@ should be acceptable", @(statusCode));

        NSError *error = nil;
        [self.responseSerializer validateResponse:response data:[@"text" dataUsingEncoding:NSUTF8StringEncoding] error:&error];

        XCTAssertNil(error, @"Error handling status code %@", @(statusCode));
    }];
}

- (void)testThatAFHTTPResponseSerializationFailsAll4XX5XXStatusCodes {
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(400, 200)];
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger statusCode, BOOL *stop) {
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:statusCode HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"text/html"}];

        XCTAssert(![self.responseSerializer.acceptableStatusCodes containsIndex:statusCode], @"Status code %@ should not be acceptable", @(statusCode));

        NSError *error = nil;
        [self.responseSerializer validateResponse:response data:[@"text" dataUsingEncoding:NSUTF8StringEncoding] error:&error];

        XCTAssertNotNil(error, @"Did not fail handling status code %@",@(statusCode));
    }];
}

- (void)testThatValidationHandleResponseContentTypeIncludedIntoAcceptableContentTypes {
    self.responseSerializer.acceptableContentTypes = [[NSSet alloc] initWithObjects:@"text/html", @"application/json", @"text/json", @"image/jpeg", [NSNull null], nil];
    [self.responseSerializer.acceptableContentTypes enumerateObjectsUsingBlock:^(id contentType, BOOL *stop) {
        NSDictionary *headerFields = [contentType isKindOfClass:[NSNull class]] ? @{} : @{@"Content-Type": contentType};
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:200 HTTPVersion:@"1.1" headerFields:headerFields];
        
        XCTAssert([self.responseSerializer.acceptableContentTypes containsObject:contentType], @"Content-Type: %@ should be included in the acceptable content types", contentType);
        
        NSError *error = nil;
        [self.responseSerializer validateResponse:response data:[@"text" dataUsingEncoding:NSUTF8StringEncoding] error:&error];
        
        XCTAssertNil(error, @"Unexpected failure in validation of Content-Type: %@", contentType);
    }];
}

- (void)testThatValidationFailsWhenResponseContentTypeIsNotIncludedIntoAcceptableContentTypes {
    self.responseSerializer.acceptableContentTypes = [[NSSet alloc] initWithObjects:@"text/html", nil];
    NSSet *testableContentTypes = [[NSSet alloc] initWithObjects:@"image/tiff", [NSNull null], nil];
    [testableContentTypes enumerateObjectsUsingBlock:^(id contentType, BOOL *stop) {
        NSDictionary *headerFields = [contentType isKindOfClass:[NSNull class]] ? @{} : @{@"Content-Type": contentType};
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:200 HTTPVersion:@"1.1" headerFields:headerFields];
        XCTAssert(![self.responseSerializer.acceptableContentTypes containsObject:contentType], @"Content-Type: %@ shouldn't be included in the acceptable content types", contentType);
        
        NSError *error = nil;
        [self.responseSerializer validateResponse:response data:[@"text" dataUsingEncoding:NSUTF8StringEncoding] error:&error];
        
        XCTAssertNotNil(error, @"Did not fail when Content-Type: %@ is not included into the acceptable ones", contentType);
    }];
}

@end
