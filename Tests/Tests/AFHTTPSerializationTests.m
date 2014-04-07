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
#import "AFURLRequestSerialization.h"

@interface AFMultipartBodyStream : NSInputStream <NSStreamDelegate>

@property (readwrite, nonatomic, strong) NSMutableArray *HTTPBodyParts;

@end

@protocol AFMultipartFormDataTest <AFMultipartFormData>

- (instancetype)initWithURLRequest:(NSMutableURLRequest *)urlRequest
                    stringEncoding:(NSStringEncoding)encoding;
@property (readwrite, nonatomic, strong) AFMultipartBodyStream *bodyStream;

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

@interface AFHTTPSerializationTests : AFTestCase
@end

@implementation AFHTTPSerializationTests

#pragma mark - AFHTTPResponseSerializationTests

- (void)testThatAFHTTPResponseSerializationHandlesAll2XXCodes {
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger statusCode, BOOL *stop) {
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:statusCode HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"text/html"}];

        AFHTTPResponseSerializer *serializer = [AFHTTPResponseSerializer serializer];
        XCTAssert([serializer.acceptableStatusCodes containsIndex:statusCode], @"Status code %@ should be acceptable", @(statusCode));

        NSError *error = nil;
        [serializer validateResponse:response data:[@"text" dataUsingEncoding:NSUTF8StringEncoding] error:&error];

        XCTAssertNil(error, @"Error handling status code %@", @(statusCode));
    }];
}

- (void)testThatAFHTTPResponseSerializationFailsAll4XX5XXStatusCodes {
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(400, 200)];
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger statusCode, BOOL *stop) {
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.baseURL statusCode:statusCode HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"text/html"}];

        AFHTTPResponseSerializer *serializer = [AFHTTPResponseSerializer serializer];
        XCTAssert(![serializer.acceptableStatusCodes containsIndex:statusCode], @"Status code %@ should not be acceptable", @(statusCode));

        NSError *error = nil;
        [serializer validateResponse:response data:[@"text" dataUsingEncoding:NSUTF8StringEncoding] error:&error];

        XCTAssertNotNil(error, @"Did not fail handling status code %@",@(statusCode));
    }];
}

#pragma mark - AFHTTPRequestSerializationTests

- (void)testThatAFHTTPRequestSerialiationSerializesDefaultQueryParametersCorrectly{
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    
    NSURLRequest *originalRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://test.com"]];
    
    NSURLRequest *serializedRequest = [serializer requestBySerializingRequest:originalRequest
                                                               withParameters:@{@"key":@"value"}
                                                                        error:nil];
    NSString *queryString = serializedRequest.URL.query;
    XCTAssertTrue([queryString isEqualToString:@"key=value"], @"Default Query parameters have not been serialized correctly (%@)",queryString);
}

- (void)testThatAFHTTPRequestSerialiationSerializesQueryParametersCorrectlyFromQuerySerializationBlock{
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    [serializer
     setQueryStringSerializationWithBlock:^NSString *(NSURLRequest *request, NSDictionary *parameters, NSError *__autoreleasing *error) {
         __block NSMutableString *query = [NSMutableString stringWithString:@""];
         [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
             [query appendFormat:@"%@**%@",key,obj];
         }];
         return query;
     }];
    
    NSURLRequest *originalRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://test.com"]];
    
    NSURLRequest *serializedRequest = [serializer requestBySerializingRequest:originalRequest
                                                               withParameters:@{@"key":@"value"}
                                                                        error:nil];
    NSString *queryString = serializedRequest.URL.query;
    XCTAssertTrue([queryString isEqualToString:@"key**value"], @"Custom Query parameters have not been serialized correctly (%@) by the query string block.",queryString);
}

- (void)testThatAFHTTPRequestSerialiationSerializesMIMETypeCorrectly
{
    NSMutableURLRequest *originalRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://test.com"]];
    Class streamClass = NSClassFromString(@"AFStreamingMultipartFormData");
    id <AFMultipartFormDataTest> formData = [[streamClass alloc] initWithURLRequest:originalRequest stringEncoding:NSUTF8StringEncoding];
    
    NSURL *fileURL = [NSURL fileURLWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"adn_0" ofType:@"cer"]];
    
    [formData appendPartWithFileURL:fileURL name:@"test" error:NULL];
    
    AFHTTPBodyPart *part = [formData.bodyStream.HTTPBodyParts firstObject];
    
    XCTAssertTrue([part.headers[@"Content-Type"] isEqualToString:@"application/x-x509-ca-cert"], @"MIME Type has not been obtained correctly (%@)", part.headers[@"Content-Type"]);
    
}

@end
