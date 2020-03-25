// AFWKWebViewTests.m
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
#import <WebKit/WebKit.h>
#import "AFTestCase.h"
#import "WKWebView+AFNetworking.h"

@interface AFWKWebViewTests : AFTestCase <WKNavigationDelegate>

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) WKNavigation *navigation;
@property (nonatomic, strong) NSURLRequest *HTMLRequest;
@property (nonatomic, strong) NSURLRequest *largeHTMLRequest;
@property (nonatomic, strong) NSURLRequest *headerRequest;
@property (nonatomic, strong) NSProgress *progressCapture;

@end

@implementation AFWKWebViewTests

-(void)setUp {
    [super setUp];
    self.webView = [WKWebView new];
    self.webView.navigationDelegate = self;
    self.navigation = [WKNavigation new];
    self.HTMLRequest = [NSURLRequest requestWithURL:[self.baseURL URLByAppendingPathComponent:@"html"]
                                        cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                    timeoutInterval:self.networkTimeout];
    NSURL * largeURL = [[self.baseURL URLByAppendingPathComponent:@"bytes"] URLByAppendingPathComponent:@(1024 * 1024).stringValue];
    self.largeHTMLRequest = [NSURLRequest requestWithURL:largeURL
                                             cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                         timeoutInterval:self.networkTimeout];
    NSMutableURLRequest *customHeaderRequest = [NSMutableURLRequest requestWithURL:[self.baseURL URLByAppendingPathComponent:@"headers"]];
    [customHeaderRequest setValue:@"Custom-Header-Value" forHTTPHeaderField:@"Custom-Header-Field"];
    self.headerRequest = customHeaderRequest;
}

- (void)testNilProgressDoesNotCauseCrash {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];
    [self.webView
     loadRequest:self.HTMLRequest
     navigation:self.navigation
     progress:nil
     success:^NSString * _Nonnull(NSHTTPURLResponse * _Nonnull response, NSString * _Nonnull HTML) {
         [expectation fulfill];
         return HTML;
     } failure:^(NSError * _Nonnull error) {
         XCTFail(@"Request %@ failed with error %@", self.HTMLRequest, error);
         [expectation fulfill];
     }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testNUllProgressDoesNotCauseCrash {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];
    [self.webView
     loadRequest:self.HTMLRequest
     navigation:self.navigation
     progress:NULL
     success:^NSString * _Nonnull(NSHTTPURLResponse * _Nonnull response, NSString * _Nonnull HTML) {
         [expectation fulfill];
         return HTML;
     } failure:^(NSError * _Nonnull error) {
         XCTFail(@"Request %@ failed with error %@", self.HTMLRequest, error);
         [expectation fulfill];
     }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testProgressIsSet {
    NSProgress* progress = nil;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];

    [self.webView
     loadRequest:self.largeHTMLRequest
     navigation:self.navigation
     progress:&progress
     success:^NSString * _Nonnull(NSHTTPURLResponse * _Nonnull response, NSString * _Nonnull HTML) {
         [expectation fulfill];
         return HTML;
     } failure:^(NSError * _Nonnull error) {
         XCTFail(@"Request %@ failed with error %@", self.largeHTMLRequest, error);
         [expectation fulfill];
     }];
    [self keyValueObservingExpectationForObject:progress
                                        keyPath:@"fractionCompleted"
                                  expectedValue:@(1.0)];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testRequestWithCustomHeaders {

    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];
    [self.webView
     loadRequest:self.headerRequest
     navigation:self.navigation
     progress:NULL
     success:^NSString * _Nonnull(NSHTTPURLResponse * _Nonnull response, NSString * _Nonnull string) {
         // Here string is actually JSON
         NSDictionary<NSString *, NSDictionary *> *responseObject = [NSJSONSerialization JSONObjectWithData:[string dataUsingEncoding:NSUTF8StringEncoding] options:(NSJSONReadingOptions)0 error:nil];

         NSDictionary<NSString *, NSString *> *headers = responseObject[@"headers"];
         XCTAssertTrue([headers[@"Custom-Header-Field"] isEqualToString:@"Custom-Header-Value"]);
         [expectation fulfill];
         return string;
     } failure:^(NSError * _Nonnull error) {
         XCTFail(@"Request %@ failed with error %@", self.headerRequest, error);
         [expectation fulfill];
     }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    XCTFail(@"Navigation failed with error %@", error);
}

@end
