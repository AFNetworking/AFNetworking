// AFPropertyListResponseSerializerTests.m
// Copyright (c) 2011–2015 Alamofire Software Foundation (http://alamofire.org/)
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

@interface AFPropertyListResponseSerializerTests : AFTestCase
@property (nonatomic, strong) AFPropertyListResponseSerializer *responseSerializer;
@end

@implementation AFPropertyListResponseSerializerTests

- (void)setUp {
    [super setUp];
    self.responseSerializer = [AFPropertyListResponseSerializer serializer];
}

#pragma mark -

- (void)testThatPropertyListResponseSerializerHandles204 {
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:204 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/x-plist"}];
    NSError *error;
    id responseObject = [self.responseSerializer responseObjectForResponse:response data:nil error:&error];

    XCTAssertNil(responseObject, @"Response should be nil when handling 204 with application/x-plist");
    XCTAssertNil(error, @"Error handling application/x-plist");
}

@end
