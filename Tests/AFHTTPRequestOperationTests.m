//
//  AFHTTPRequestOperationTests.m
//  AFNetworking
//
//  Created by Blake Watters on 5/10/13.
//  Copyright (c) 2013 AFNetworking. All rights reserved.
//

#import "AFNetworkingTests.h"

@interface AFHTTPRequestOperationTests : SenTestCase
@end

@implementation AFHTTPRequestOperationTests

- (void)testThatOperationInvokesSuccessCompletionBlockWithResponseObjectOnSuccess
{
    __block id blockResponseObject = nil;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/get" relativeToURL:AFNetworkingTestsBaseURL()]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        blockResponseObject = responseObject;
    } failure:nil];
    [operation start];
    expect([operation isFinished]).will.beTruthy();
    expect(blockResponseObject).willNot.beNil();
}

- (void)testThatOperationInvokesFailureCompletionBlockWithErrorOnFailure
{
    __block NSError *blockError = nil;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/404" relativeToURL:AFNetworkingTestsBaseURL()]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:nil failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        blockError = error;
    }];
    [operation start];
    expect([operation isFinished]).will.beTruthy();
    expect(blockError).willNot.beNil();
}

- (void)testThatCancellationOfRequestOperationSetsError
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/delay/5" relativeToURL:AFNetworkingTestsBaseURL()]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation start];
    expect([operation isExecuting]).will.beTruthy();
    [operation cancel];
    expect(operation.error).willNot.beNil();
    expect(operation.error.code).to.equal(NSURLErrorCancelled);
}

- (void)testThatCancellationOfRequestOperationInvokesFailureCompletionBlock
{
    __block NSError *blockError = nil;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/delay/5" relativeToURL:AFNetworkingTestsBaseURL()]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:nil failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        blockError = error;
    }];
    [operation start];
    expect([operation isExecuting]).will.beTruthy();
    [operation cancel];
    expect(blockError).willNot.beNil();
    expect(blockError.code).to.equal(NSURLErrorCancelled);
}

@end
