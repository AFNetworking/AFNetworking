// AFJSONRequestOperationTests.m
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

#import "AFNetworkingTests.h"

@interface AFJSONRequestOperationTests : SenTestCase
@property (readwrite, nonatomic, strong) NSURL *baseURL;
@end

@implementation AFJSONRequestOperationTests

- (void)setUp {
    self.baseURL = [NSURL URLWithString:AFNetworkingTestsBaseURLString];
}

- (void)testThatJSONRequestOperationAcceptsApplicationJSON {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/response-headers?Content-Type=application/json" relativeToURL:self.baseURL]];
    AFJSONRequestOperation *operation = [[AFJSONRequestOperation alloc] initWithRequest:request];

    [operation start];
    expect([operation isFinished]).will.beTruthy();
    expect(operation.error).will.beNil();
}

- (void)testThatJSONRequestOperationAcceptsTextJSON {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/response-headers?Content-Type=text/json" relativeToURL:self.baseURL]];
    AFJSONRequestOperation *operation = [[AFJSONRequestOperation alloc] initWithRequest:request];

    [operation start];
    expect([operation isFinished]).will.beTruthy();
    expect(operation.error).will.beNil();
}

- (void)testThatJSONRequestOperationAcceptsTextJavascript {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/response-headers?Content-Type=text/javascript" relativeToURL:self.baseURL]];
    AFJSONRequestOperation *operation = [[AFJSONRequestOperation alloc] initWithRequest:request];

    [operation start];
    expect([operation isFinished]).will.beTruthy();
    expect(operation.error).will.beNil();
}

- (void)testThatJSONRequestOperationAcceptsCustomContentType {
    [AFJSONRequestOperation addAcceptableContentTypes:[NSSet setWithObject:@"application/customjson"]];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/response-headers?Content-Type=application/customjson" relativeToURL:self.baseURL]];
    AFJSONRequestOperation *operation = [[AFJSONRequestOperation alloc] initWithRequest:request];

    [operation start];
    expect([operation isFinished]).will.beTruthy();
    expect(operation.error).will.beNil();
}

- (void)testThatJSONRequestOperationDoesNotAcceptInvalidContentType {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/response-headers?Content-Type=application/no-json" relativeToURL:self.baseURL]];
    AFJSONRequestOperation *operation = [[AFJSONRequestOperation alloc] initWithRequest:request];

    [operation start];
    expect([operation isFinished]).will.beTruthy();
    expect(operation.error).willNot.beNil();
}

- (void)testThatJSONResponseObjectIsNotNilWhenValidJSONIsReturned {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/response-headers?Content-Type=application/json" relativeToURL:self.baseURL]];
    AFJSONRequestOperation *operation = [[AFJSONRequestOperation alloc] initWithRequest:request];

    [operation start];
    expect([operation isFinished]).will.beTruthy();
    expect(operation.responseJSON).willNot.beNil();
}

- (void)testThatJSONResponseObjectIsNilWhenErrorOccurs {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/status/404" relativeToURL:self.baseURL]];
    AFJSONRequestOperation *operation = [[AFJSONRequestOperation alloc] initWithRequest:request];

    [operation start];
    expect([operation isFinished]).will.beTruthy();
    expect(operation.responseJSON).will.beNil();
}

@end
