//
//  AFJSONRequestOperationTests.m
//  AFNetworking Tests
//
//  Created by Kevin Harwood on 5/16/13.
//  Copyright (c) 2013 AFNetworking. All rights reserved.
//

#import "AFNetworkingTests.h"
#import "AFJSONRequestOperation.h"

@interface AFJSONRequestOperationTests : SenTestCase

@property (readwrite, nonatomic, strong) NSURL *baseURL;
@end

@implementation AFJSONRequestOperationTests
@synthesize baseURL = _baseURL;

- (void)setUp {
    self.baseURL = [NSURL URLWithString:AFNetworkingTestsBaseURLString];
}

- (void)testThatJSONRequestOperationAcceptsApplicationJSON{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/response-headers?Content-Type=application/json" relativeToURL:self.baseURL]];
    AFJSONRequestOperation *operation = [[AFJSONRequestOperation alloc] initWithRequest:request];
    [operation start];
    expect([operation isFinished]).will.beTruthy();
    expect(operation.error).will.beNil();
}

- (void)testThatJSONRequestOperationAcceptsTextJSON{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/response-headers?Content-Type=text/json" relativeToURL:self.baseURL]];
    AFJSONRequestOperation *operation = [[AFJSONRequestOperation alloc] initWithRequest:request];
    [operation start];
    expect([operation isFinished]).will.beTruthy();
    expect(operation.error).will.beNil();
}

- (void)testThatJSONRequestOperationAcceptsTextJavascript{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/response-headers?Content-Type=text/javascript" relativeToURL:self.baseURL]];
    AFJSONRequestOperation *operation = [[AFJSONRequestOperation alloc] initWithRequest:request];
    [operation start];
    expect([operation isFinished]).will.beTruthy();
    expect(operation.error).will.beNil();
}

- (void)testThatJSONRequestOperationAcceptsCustomContentType{
    [AFJSONRequestOperation addAcceptableContentTypes:[NSSet setWithObject:@"application/customjson"]];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/response-headers?Content-Type=application/customjson" relativeToURL:self.baseURL]];
    AFJSONRequestOperation *operation = [[AFJSONRequestOperation alloc] initWithRequest:request];
    [operation start];
    expect([operation isFinished]).will.beTruthy();
    expect(operation.error).will.beNil();
}

- (void)testThatJSONRequestOperationDoesNotAcceptInvalidContentType{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/response-headers?Content-Type=application/no-json" relativeToURL:self.baseURL]];
    AFJSONRequestOperation *operation = [[AFJSONRequestOperation alloc] initWithRequest:request];
    [operation start];
    expect([operation isFinished]).will.beTruthy();
    expect(operation.error).willNot.beNil();
}

- (void)testThatJSONResponseObjectIsNotNilWhenValidJSONIsReturned{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/response-headers?Content-Type=application/json" relativeToURL:self.baseURL]];
    AFJSONRequestOperation *operation = [[AFJSONRequestOperation alloc] initWithRequest:request];
    [operation start];
    expect([operation isFinished]).will.beTruthy();
    expect(operation.responseJSON).willNot.beNil();
}

- (void)testThatJSONResponseObjectIsNilWhenErrorOccurs{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/status/404" relativeToURL:self.baseURL]];
    AFJSONRequestOperation *operation = [[AFJSONRequestOperation alloc] initWithRequest:request];
    [operation start];
    expect([operation isFinished]).will.beTruthy();
    expect(operation.responseJSON).will.beNil();
}

@end
