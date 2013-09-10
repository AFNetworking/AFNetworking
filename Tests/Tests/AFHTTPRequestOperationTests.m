//
//  AFHTTPRequestOperationTests.m
//  AFNetworking Tests
//
//  Created by Kevin Harwood on 9/10/13.
//  Copyright (c) 2013 AFNetworking. All rights reserved.
//

#import "AFTestCase.h"

@interface AFHTTPRequestOperationTests : AFTestCase

@end

@implementation AFHTTPRequestOperationTests

- (void)testThatOperationInvokesSuccessCompletionBlockWithResponseObjectOnSuccess {
    __block id blockResponseObject = nil;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/get" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    //AFHTTPOperation currently does not have a default response serializer
    [operation setResponseSerializer:[AFHTTPResponseSerializer serializer]];
    
    [operation
     setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id blockResponseObject) {
         blockResponseObject = blockResponseObject;
     }
     failure:nil];
    
    [operation start];
    expect([operation isFinished]).will.beTruthy();
    expect(blockResponseObject).willNot.beNil();
}

- (void)testThatOperationInvokesFailureCompletionBlockWithErrorOnFailure {
    __block NSError *blockError = nil;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/status/404" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    //AFHTTPOperation currently does not have a default response serializer
    [operation setResponseSerializer:[AFHTTPResponseSerializer serializer]];
    
    [operation
     setCompletionBlockWithSuccess:nil
     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         blockError = error;
     }];
    
    [operation start];
    expect([operation isFinished]).will.beTruthy();
    expect(blockError).willNot.beNil();
}

@end
