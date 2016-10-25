// AFPropertyListRequestSerializerTests.m
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

@interface AFPropertyListRequestSerializerTests : AFTestCase
@property (nonatomic, strong) AFPropertyListRequestSerializer *requestSerializer;
@end

@implementation AFPropertyListRequestSerializerTests

- (void)setUp {
    [super setUp];
    self.requestSerializer = [AFPropertyListRequestSerializer serializer];
}

#pragma mark -

- (void)testThatPropertyListRequestSerializerAcceptsPlist {
    NSDictionary *parameters = @{@"key":@"value"};
    NSError *error = nil;
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"POST" URLString:self.baseURL.absoluteString parameters:parameters error:&error];
    
    XCTAssertNotNil(request, @"Expected non-nil request.");
}

- (void)testThatPropertyListRequestSerializerHandlesInvalidPlist {
    NSDictionary *parameters = @{@42:@"value"};
    NSError *error = nil;
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"POST" URLString:self.baseURL.absoluteString parameters:parameters error:&error];
    
    XCTAssertNil(request, @"Expected nil request.");
    XCTAssertNotNil(error, @"Expected non-nil error.");
}

@end
