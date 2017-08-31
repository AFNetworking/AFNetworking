// AFPropertyListResponseSerializerTests.m
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

- (void)testThatPropertyListResponseSerializerAcceptsPlistData {
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:@{@"foo": @"bar"} format:NSPropertyListXMLFormat_v1_0 options:0 error:NULL];
    
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/x-plist"}];
    NSError *error = nil;
    id responseObject = [self.responseSerializer responseObjectForResponse:response data:data error:&error];
    
    XCTAssertTrue([responseObject isKindOfClass:[NSDictionary class]], @"Expected valid dictionary.");
}

- (void)testThatPropertyListResponseSerializerHandlesInvalidPlistData {
    NSData *data = [NSJSONSerialization dataWithJSONObject:@{@"foo": @"bar"} options:(NSJSONWritingOptions)0 error:nil];
    
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/x-plist"}];
    NSError *error = nil;
    id responseObject = [self.responseSerializer responseObjectForResponse:response data:data error:&error];
    
    XCTAssertNil(responseObject, @"Expected nil responseObject.");
    XCTAssertNotNil(error, @"Expected non-nil error.");
}

- (void)testThatPropertyListResponseSerializerHandles204 {
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:204 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/x-plist"}];
    NSError *error;
    id responseObject = [self.responseSerializer responseObjectForResponse:response data:nil error:&error];

    XCTAssertNil(responseObject, @"Response should be nil when handling 204 with application/x-plist");
    XCTAssertNil(error, @"Error handling application/x-plist");
}

- (void)testResponseSerializerCanBeCopied {
    [self.responseSerializer setAcceptableContentTypes:[NSSet setWithObject:@"test/type"]];
    [self.responseSerializer setAcceptableStatusCodes:[NSIndexSet indexSetWithIndex:100]];
    [self.responseSerializer setFormat:NSPropertyListXMLFormat_v1_0];
    [self.responseSerializer setReadOptions:NSPropertyListMutableContainers];

    AFPropertyListResponseSerializer *copiedSerializer = [self.responseSerializer copy];
    XCTAssertNotNil(copiedSerializer);
    XCTAssertNotEqual(copiedSerializer, self.responseSerializer);
    XCTAssertEqual(copiedSerializer.format, self.responseSerializer.format);
    XCTAssertEqual(copiedSerializer.readOptions, self.responseSerializer.readOptions);
    XCTAssertEqual(copiedSerializer.acceptableContentTypes, self.responseSerializer.acceptableContentTypes);
    XCTAssertEqual(copiedSerializer.acceptableStatusCodes, self.responseSerializer.acceptableStatusCodes);
}

- (void)testResponseSerializerCanBeArchivedAndUnarchived {
    NSData *archive = [NSKeyedArchiver archivedDataWithRootObject:self.responseSerializer];
    XCTAssertNotNil(archive);
    AFPropertyListResponseSerializer *unarchivedSerializer = [NSKeyedUnarchiver unarchiveObjectWithData:archive];
    XCTAssertNotNil(unarchivedSerializer);
    XCTAssertNotEqual(unarchivedSerializer, self.responseSerializer);
    XCTAssertTrue(unarchivedSerializer.format == self.responseSerializer.format);
    XCTAssertTrue(unarchivedSerializer.readOptions == self.responseSerializer.readOptions);
}

@end
