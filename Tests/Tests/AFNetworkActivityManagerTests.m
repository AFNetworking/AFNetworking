// AFNetworkActivityManagerTests.m
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

#import "AFNetworkActivityIndicatorManager.h"
#import "AFHTTPRequestOperation.h"

@interface AFNetworkActivityManagerTests : AFTestCase
@property (nonatomic, strong) AFNetworkActivityIndicatorManager *networkActivityIndicatorManager;
@property (nonatomic, assign) BOOL isNetworkActivityIndicatorVisible;
@property (nonatomic, strong) id mockApplication;
@end

#pragma mark -

@implementation AFNetworkActivityManagerTests

- (void)setUp {
    [super setUp];

    self.networkActivityIndicatorManager = [[AFNetworkActivityIndicatorManager alloc] init];
    self.networkActivityIndicatorManager.enabled = YES;

    self.mockApplication = [OCMockObject mockForClass:[UIApplication class]];
    [[[self.mockApplication stub] andReturn:self.mockApplication] sharedApplication];

    [[[self.mockApplication stub] andDo:^(NSInvocation *invocation) {
        [invocation setReturnValue:(void *)&_isNetworkActivityIndicatorVisible];
    }] isNetworkActivityIndicatorVisible];

    [[[self.mockApplication stub] andDo:^(NSInvocation *invocation) {
        [invocation getArgument:&_isNetworkActivityIndicatorVisible atIndex:2];
    }] setNetworkActivityIndicatorVisible:YES];
}

- (void)tearDown {
    [super tearDown];
    [self.mockApplication stopMocking];
    
    self.mockApplication = nil;
    self.networkActivityIndicatorManager = nil;
}

#pragma mark -

- (void)testThatNetworkActivityIndicatorTurnsOffIndicatorWhenRequestSucceeds {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/get" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        expect([self.mockApplication isNetworkActivityIndicatorVisible]).will.beFalsy();
    } failure:nil];

    [operation start];

    expect([self.mockApplication isNetworkActivityIndicatorVisible]).will.beTruthy();
}

- (void)testThatNetworkActivityIndicatorTurnsOffIndicatorWhenRequestFails {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/status/500" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:nil failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        expect([self.mockApplication isNetworkActivityIndicatorVisible]).will.beFalsy();
    }];

    [operation start];

    expect([self.mockApplication isNetworkActivityIndicatorVisible]).will.beTruthy();
}

- (void)testThatNetworkActivityIsUnchangedWhenManagerIsDisabled {
    self.networkActivityIndicatorManager.enabled = NO;

    __block BOOL didChangeNetworkActivityIndicatorVisible = NO;

    [[[self.mockApplication stub] andDo:^(NSInvocation *invocation) {
        didChangeNetworkActivityIndicatorVisible = YES;
    }] setNetworkActivityIndicatorVisible:YES];

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/get" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:nil failure:nil];

    [operation start];

    expect(didChangeNetworkActivityIndicatorVisible).will.beFalsy();
}

@end
