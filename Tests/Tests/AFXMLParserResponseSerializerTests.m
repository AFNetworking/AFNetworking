// AFXMLParserResponseSerializerTests.m
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

static NSData * AFXMLTestData() {
    return [@"<?xml version=\"1.0\" encoding=\"UTF-8\"?><foo attr1=\"1\" attr2=\"2\"><bar>someValue</bar></foo>" dataUsingEncoding:NSUTF8StringEncoding];
}

#pragma mark -

@interface AFXMLParserResponseSerializerTests : AFTestCase
@property (nonatomic, strong) AFXMLParserResponseSerializer *responseSerializer;
@end

#pragma mark -

@implementation AFXMLParserResponseSerializerTests

- (void)setUp {
    [super setUp];
    self.responseSerializer = [AFXMLParserResponseSerializer serializer];
}

- (void)testThatXMLParserResponseSerializerAcceptsApplicationXMLMimeType {
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/xml"}];
    NSError *error = nil;
    [self.responseSerializer validateResponse:response data:AFXMLTestData() error:&error];

    XCTAssertNil(error, @"Error handling application/xml");
}

- (void)testThatXMLParserResponseSerializerAcceptsTextXMLMimeType {
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"text/xml"}];
    NSError *error = nil;
    [self.responseSerializer validateResponse:response data:AFXMLTestData() error:&error];

    XCTAssertNil(error, @"Error handling text/xml");
}

- (void)testThatXMLParserResponseSerializerDoesNotAcceptsNonStandardXMLMimeType {
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"nonstandard/xml"}];
    NSError *error = nil;
    [self.responseSerializer validateResponse:response data:AFXMLTestData() error:&error];

    XCTAssertNotNil(error, @"Error should have been thrown for nonstandard/xml");
}

- (void)testThatXMLParserResponseSerializerReturnsNSXMLParserObjectForValidXML {
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/xml"}];
    NSError *error = nil;
    id responseObject = [self.responseSerializer responseObjectForResponse:response data:AFXMLTestData() error:&error];

    XCTAssertNil(error, @"Serialization error should be nil");
    XCTAssert([responseObject isKindOfClass:[NSXMLParser class]], @"Expected response to be a NSXMLParser");
}

- (void)testThatXMLParserResponseSerializerCanBeCopied {
    [self.responseSerializer setAcceptableStatusCodes:[NSIndexSet indexSetWithIndex:100]];
    [self.responseSerializer setAcceptableContentTypes:[NSSet setWithObject:@"test/type"]];

    AFXMLParserResponseSerializer *copiedSerializer = [self.responseSerializer copy];
    XCTAssertNotEqual(copiedSerializer, self.responseSerializer);
    XCTAssertEqual(copiedSerializer.acceptableStatusCodes, self.responseSerializer.acceptableStatusCodes);
    XCTAssertEqual(copiedSerializer.acceptableContentTypes, self.responseSerializer.acceptableContentTypes);
}

@end
