//
//  AFWKWebViewTests.m
//  AFNetworking
//
//  Created by Sebastiaan Seegers on 02/09/2019.
//  Copyright © 2019 AFNetworking. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "AFTestCase.h"
#import "WKWebView+AFNetworking.h"

@interface AFWKWebViewTests : AFTestCase

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) WKNavigation *navigation;
@property (nonatomic, strong) NSURLRequest *HTMLRequest;

@end

@implementation AFWKWebViewTests

-(void)setUp {
    [super setUp];
    self.webView = [WKWebView new];
    self.navigation = [WKNavigation new];
    self.HTMLRequest = [NSURLRequest requestWithURL:[self.baseURL URLByAppendingPathComponent:@"html"]];
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
    } failure:nil];
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
     } failure:nil];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testProgressIsSet {
    NSProgress* progress = nil;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should succeed"];
    [self.webView
     loadRequest:self.HTMLRequest
     navigation:self.navigation
     progress:&progress
     success:^NSString * _Nonnull(NSHTTPURLResponse * _Nonnull response, NSString * _Nonnull HTML) {
         [expectation fulfill];
         return HTML;
    } failure:nil];
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
     navigation:self.navigation
     progress:NULL
     success:^NSString * _Nonnull(NSHTTPURLResponse * _Nonnull response, NSString * _Nonnull string) {
         // Here string is actually JSON
         NSDictionary<NSString *, NSDictionary *> *responseObject = [NSJSONSerialization JSONObjectWithData:[string dataUsingEncoding:NSUTF8StringEncoding] options:(NSJSONReadingOptions)0 error:nil];

         NSDictionary<NSString *, NSString *> *headers = responseObject[@"headers"];
         XCTAssertTrue([headers[@"Custom-Header-Field"] isEqualToString:@"Custom-Header-Value"]);
         [expectation fulfill];
         return string;
    } failure:nil];
    [self waitForExpectationsWithCommonTimeout];
}

@end
