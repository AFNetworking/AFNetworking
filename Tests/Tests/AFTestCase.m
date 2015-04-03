// AFTestCase.m
//
// Copyright (c) 2013-2015 AFNetworking (http://afnetworking.com)
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
#import <AFNetworking/AFURLSessionManager.h>

NSString * const AFNetworkingTestsBaseURLString = @"https://httpbin.org/";
float const AFNetworkingDefaultTestTimeout = 5.0;

@implementation AFTestCase

- (void)setUp {
    [super setUp];
    [Expecta setAsynchronousTestTimeout:AFNetworkingDefaultTestTimeout];
    if ([[self class] requiresSessionAPIAvailability] && [AFURLSessionManager isAvailable]) {
        [self setUpSessionTest];
    }
}

- (void)tearDown {
    [super tearDown];
    if ([[self class] requiresSessionAPIAvailability] && [AFURLSessionManager isAvailable]) {
        [self tearDownSessionTest];
    }
}

+ (NSArray*)testInvocations {
    return ([self requiresSessionAPIAvailability] && ![AFURLSessionManager isAvailable]) ? @[] : [super testInvocations];
}

#pragma mark -

- (NSURL *)baseURL {
    return [NSURL URLWithString:AFNetworkingTestsBaseURLString];
}

#pragma mark - NSURLSession-dependent tests

+ (BOOL)requiresSessionAPIAvailability {
    return NO;
}

- (void)setUpSessionTest {
}

- (void)tearDownSessionTest {
}

@end
