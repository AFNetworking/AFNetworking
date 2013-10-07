// AFHTTPSerializationTests.m
//
// Copyright (c) 2013 AFNetworking (http://afnetworking.com)
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

@interface AFHTTPSerializationTests : AFTestCase
@end

@implementation AFHTTPSerializationTests

- (void)testThatAFHTTPResponseSerializationHandlesAll2XXCodes {
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger statusCode, BOOL *stop) {
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:statusCode HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"text/html"}];

        AFHTTPResponseSerializer *serializer = [AFHTTPResponseSerializer serializer];
        XCTAssert([serializer.acceptableStatusCodes containsIndex:statusCode], @"Status code %d should be acceptable", statusCode);

        NSError *error = nil;
        [serializer validateResponse:response data:[@"text" dataUsingEncoding:NSUTF8StringEncoding] error:&error];

        XCTAssertNil(error, @"Error handling status code %d", statusCode);
    }];
}

- (void)testThatAFHTTPResponseSerializationFailsAll4XX5XXStatusCodes {
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(400, 200)];
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger statusCode, BOOL *stop) {
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:statusCode HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"text/html"}];

        AFHTTPResponseSerializer *serializer = [AFHTTPResponseSerializer serializer];
        XCTAssert(![serializer.acceptableStatusCodes containsIndex:statusCode], @"Status code %d should not be acceptable", statusCode);

        NSError *error = nil;
        [serializer validateResponse:response data:[@"text" dataUsingEncoding:NSUTF8StringEncoding] error:&error];

        XCTAssertNotNil(error, @"Did not fail handling status code %d",statusCode);
    }];
}

@end
