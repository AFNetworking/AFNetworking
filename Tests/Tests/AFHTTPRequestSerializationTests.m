// AFHTTPSerializationTests.m
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

#import "AFURLRequestSerialization.h"

@interface AFMultipartBodyStream : NSInputStream <NSStreamDelegate>
@property (readwrite, nonatomic, strong) NSMutableArray *HTTPBodyParts;
@end

@protocol AFMultipartFormDataTest <AFMultipartFormData>
@property (readwrite, nonatomic, strong) AFMultipartBodyStream *bodyStream;

- (instancetype)initWithURLRequest:(NSMutableURLRequest *)urlRequest
                    stringEncoding:(NSStringEncoding)encoding;
@end

@interface AFHTTPBodyPart : NSObject
@property (nonatomic, assign) NSStringEncoding stringEncoding;
@property (nonatomic, strong) NSDictionary *headers;
@property (nonatomic, copy) NSString *boundary;
@property (nonatomic, strong) id body;
@property (nonatomic, assign) NSUInteger bodyContentLength;
@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, assign) BOOL hasInitialBoundary;
@property (nonatomic, assign) BOOL hasFinalBoundary;
@property (readonly, nonatomic, assign, getter = hasBytesAvailable) BOOL bytesAvailable;
@property (readonly, nonatomic, assign) NSUInteger contentLength;

- (NSInteger)read:(uint8_t *)buffer
        maxLength:(NSUInteger)length;
@end

#pragma mark -

@interface AFHTTPRequestSerializationTests : AFTestCase
@property (nonatomic, strong) AFHTTPRequestSerializer *requestSerializer;
@end

@implementation AFHTTPRequestSerializationTests

- (void)setUp {
    [super setUp];
    self.requestSerializer = [AFHTTPRequestSerializer serializer];
}

#pragma mark -

- (void)testThatAFHTTPRequestSerialiationSerializesQueryParametersCorrectly {
    NSURLRequest *originalRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://example.com"]];
    NSURLRequest *serializedRequest = [self.requestSerializer requestBySerializingRequest:originalRequest withParameters:@{@"key":@"value"} error:nil];

    XCTAssertTrue([[[serializedRequest URL] query] isEqualToString:@"key=value"], @"Query parameters have not been serialized correctly (%@)", [[serializedRequest URL] query]);
}

- (void)testThatAFHTTPRequestSerialiationSerializesURLEncodableQueryParametersCorrectly {
    NSURLRequest *originalRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://example.com"]];
    NSURLRequest *serializedRequest = [self.requestSerializer requestBySerializingRequest:originalRequest withParameters:@{@"key":@" !\"#$%&'()*+,/"} error:nil];

    XCTAssertTrue([[[serializedRequest URL] query] isEqualToString:@"key=%20%21%22%23%24%25%26%27%28%29%2A%2B%2C%2F"], @"Query parameters have not been serialized correctly (%@)", [[serializedRequest URL] query]);
}

- (void)testThatAFHTTPRequestSerialiationSerializesURLEncodedQueryParametersCorrectly {
    NSURLRequest *originalRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://example.com"]];
    NSURLRequest *serializedRequest = [self.requestSerializer requestBySerializingRequest:originalRequest withParameters:@{@"key":@"%20%21%22%23%24%25%26%27%28%29%2A%2B%2C%2F"} error:nil];

    XCTAssertTrue([[[serializedRequest URL] query] isEqualToString:@"key=%2520%2521%2522%2523%2524%2525%2526%2527%2528%2529%252A%252B%252C%252F"], @"Query parameters have not been serialized correctly (%@)", [[serializedRequest URL] query]);
}

- (void)testThatAFHTTPRequestSerialiationSerializesQueryParametersCorrectlyFromQuerySerializationBlock {
    [self.requestSerializer setQueryStringSerializationWithBlock:^NSString *(NSURLRequest *request, NSDictionary *parameters, NSError *__autoreleasing *error) {
         __block NSMutableString *query = [NSMutableString stringWithString:@""];
         [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
             [query appendFormat:@"%@**%@",key,obj];
         }];

         return query;
     }];

    NSURLRequest *originalRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://example.com"]];
    NSURLRequest *serializedRequest = [self.requestSerializer requestBySerializingRequest:originalRequest withParameters:@{@"key":@"value"} error:nil];

    XCTAssertTrue([[[serializedRequest URL] query] isEqualToString:@"key**value"], @"Custom Query parameters have not been serialized correctly (%@) by the query string block.", [[serializedRequest URL] query]);
}

- (void)testThatAFHTTPRequestSerialiationSerializesMIMETypeCorrectly {
    NSMutableURLRequest *originalRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://example.com"]];
    Class streamClass = NSClassFromString(@"AFStreamingMultipartFormData");
    id <AFMultipartFormDataTest> formData = [[streamClass alloc] initWithURLRequest:originalRequest stringEncoding:NSUTF8StringEncoding];

    NSURL *fileURL = [NSURL fileURLWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"adn_0" ofType:@"cer"]];

    [formData appendPartWithFileURL:fileURL name:@"test" error:NULL];

    AFHTTPBodyPart *part = [formData.bodyStream.HTTPBodyParts firstObject];

    XCTAssertTrue([part.headers[@"Content-Type"] isEqualToString:@"application/x-x509-ca-cert"], @"MIME Type has not been obtained correctly (%@)", part.headers[@"Content-Type"]);
}

#pragma mark -

- (void)testThatValueForHTTPHeaderFieldReturnsSetValue {
    [self.requestSerializer setValue:@"Actual Value" forHTTPHeaderField:@"Set-Header"];
    NSString *value = [self.requestSerializer valueForHTTPHeaderField:@"Set-Header"];

    expect(value).to.equal(@"Actual Value");
}

- (void)testThatValueForHTTPHeaderFieldReturnsNilForUnsetHeader {
    NSString *value = [self.requestSerializer valueForHTTPHeaderField:@"Unset-Header"];

    expect(value).to.beNil();
}

- (void)testQueryStringSerializationCanFailWithError {
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];

    NSError *serializerError = [NSError errorWithDomain:@"TestDomain" code:0 userInfo:nil];

    [serializer setQueryStringSerializationWithBlock:^NSString *(NSURLRequest *request, NSDictionary *parameters, NSError *__autoreleasing *error) {
        *error = serializerError;
        return nil;
    }];

    NSError *error;
    NSURLRequest *request = [serializer requestWithMethod:@"GET" URLString:@"url" parameters:@{} error:&error];

    expect(request).to.beNil();
    expect(error).to.equal(serializerError);
}

@end
