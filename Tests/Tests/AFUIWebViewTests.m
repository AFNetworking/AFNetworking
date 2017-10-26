// AFUIWebViewTests.h
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

#import <XCTest/XCTest.h>
#import "AFTestCase.h"
#import "UIWebView+AFNetworking.h"

@interface AFUIWebViewTests : AFTestCase

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) NSURLRequest *HTMLRequest;

@end

@implementation AFUIWebViewTests

- (void)setUp {
    [super setUp];
    self.webView = [UIWebView new];
    self.HTMLRequest = [NSURLRequest requestWithURL:[self.baseURL URLByAppendingPathComponent:@"html"]];
}

- (void)testNilProgressDoesNotCauseCrash {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];
    [self.webView
     loadRequest:self.HTMLRequest
     progress:nil
     success:^NSString * _Nonnull(NSHTTPURLResponse * _Nonnull response, NSString * _Nonnull HTML) {
         [expectation fulfill];
         return HTML;
     }
     failure:nil];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testNULLProgressDoesNotCauseCrash {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];
    [self.webView
     loadRequest:self.HTMLRequest
     progress:NULL
     success:^NSString * _Nonnull(NSHTTPURLResponse * _Nonnull response, NSString * _Nonnull HTML) {
         [expectation fulfill];
         return HTML;
     }
     failure:nil];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testProgressIsSet {
    NSProgress* progress = nil;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];
    [self.webView
     loadRequest:self.HTMLRequest
     progress:&progress
     success:^NSString * _Nonnull(NSHTTPURLResponse * _Nonnull response, NSString * _Nonnull HTML) {
         [expectation fulfill];
         return HTML;
     }
     failure:nil];
    [self keyValueObservingExpectationForObject:progress
                                        keyPath:@"fractionCompleted"
                                  expectedValue:@(1.0)];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testRequestWithCustomHeaders {
    NSMutableURLRequest *customHeaderRequest = [NSMutableURLRequest requestWithURL:[self.baseURL URLByAppendingPathComponent:@"headers"]];
    [customHeaderRequest setValue:@"Custom-Header-Value" forHTTPHeaderField:@"Custom-Header-Field"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];
    [self.webView
     loadRequest:customHeaderRequest
     progress:NULL
     success:^NSString * _Nonnull(NSHTTPURLResponse * _Nonnull response, NSString * _Nonnull string) {
         // Here string is actually JSON.
         NSDictionary<NSString *, NSDictionary *> *responseObject = [NSJSONSerialization JSONObjectWithData:[string dataUsingEncoding:NSUTF8StringEncoding] options:(NSJSONReadingOptions)0 error:nil];

         NSDictionary<NSString *, NSString *> *headers = responseObject[@"headers"];
         XCTAssertTrue([headers[@"Custom-Header-Field"] isEqualToString:@"Custom-Header-Value"]);
         [expectation fulfill];
         return string;
     }
     failure:nil];
    [self waitForExpectationsWithCommonTimeout];
}

@end
