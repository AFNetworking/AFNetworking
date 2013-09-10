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
     setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
         blockResponseObject = responseObject;
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

- (void)testThatCancellationOfRequestOperationSetsError {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/delay/5" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    //AFHTTPOperation currently does not have a default response serializer
    [operation setResponseSerializer:[AFHTTPResponseSerializer serializer]];
    
    [operation start];
    expect([operation isExecuting]).will.beTruthy();
    
    [operation cancel];
    expect(operation.error).willNot.beNil();
    expect(operation.error.code).to.equal(NSURLErrorCancelled);
}

- (void)testThatCancellationOfRequestOperationInvokesFailureCompletionBlock {
    __block NSError *blockError = nil;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/delay/5" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    //AFHTTPOperation currently does not have a default response serializer
    [operation setResponseSerializer:[AFHTTPResponseSerializer serializer]];
    
    [operation setCompletionBlockWithSuccess:nil failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        blockError = error;
    }];
    
    [operation start];
    expect([operation isExecuting]).will.beTruthy();
    
    [operation cancel];
    expect(operation.error).willNot.beNil();
    expect(blockError).willNot.beNil();
    expect(blockError.code).will.equal(NSURLErrorCancelled);
}

- (void)testThat500StatusCodeInvokesFailureCompletionBlockWithErrorOnFailure {
    __block NSError *blockError = nil;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/status/500" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    //AFHTTPOperation currently does not have a default response serializer
    [operation setResponseSerializer:[AFHTTPResponseSerializer serializer]];
    
    [operation setCompletionBlockWithSuccess:nil failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        blockError = error;
    }];
    
    [operation start];
    expect([operation isFinished]).will.beTruthy();
    expect(blockError).willNot.beNil();
}

- (void)testThatRedirectBlockIsCalledWhen302IsEncountered {
    __block BOOL success;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/redirect/1" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    //AFHTTPOperation currently does not have a default response serializer
    [operation setResponseSerializer:[AFHTTPResponseSerializer serializer]];
    
    [operation setCompletionBlockWithSuccess:nil failure:nil];
    [operation setRedirectResponseBlock:^NSURLRequest *(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *redirectResponse) {
        if(redirectResponse){
            success = YES;
        }
        
        return request;
    }];
    
    [operation start];
    expect([operation isFinished]).will.beTruthy();
    expect(success).will.beTruthy();
}

- (void)testThatRedirectBlockIsCalledMultipleTimesWhenMultiple302sAreEncountered {
    [Expecta setAsynchronousTestTimeout:5.0];
    __block NSInteger numberOfRedirects = 0;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/redirect/5" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    //AFHTTPOperation currently does not have a default response serializer
    [operation setResponseSerializer:[AFHTTPResponseSerializer serializer]];
    
    [operation setCompletionBlockWithSuccess:nil failure:nil];
    [operation setRedirectResponseBlock:^NSURLRequest *(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *redirectResponse) {
        if(redirectResponse){
            numberOfRedirects++;
        }
        
        return request;
    }];
    
    [operation start];
    expect([operation isFinished]).will.beTruthy();
    expect(numberOfRedirects).will.equal(5);
}

#pragma mark - Pause

- (void)testThatOperationCanBePaused {
    [Expecta setAsynchronousTestTimeout:3.0];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/delay/1" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    //AFHTTPOperation currently does not have a default response serializer
    [operation setResponseSerializer:[AFHTTPResponseSerializer serializer]];
    
    [operation start];
    expect([operation isExecuting]).will.beTruthy();
    
    [operation pause];
    expect([operation isPaused]).will.beTruthy();
    [operation cancel];
}

- (void)testThatPausedOperationCanBeResumed {
    [Expecta setAsynchronousTestTimeout:3.0];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/delay/1" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    //AFHTTPOperation currently does not have a default response serializer
    [operation setResponseSerializer:[AFHTTPResponseSerializer serializer]];
    
    [operation start];
    expect([operation isExecuting]).will.beTruthy();
    
    [operation pause];
    expect([operation isPaused]).will.beTruthy();
    
    [operation resume];
    expect([operation isExecuting]).will.beTruthy();
    
    [operation cancel];
}

- (void)testThatPausedOperationCanBeCompleted {
    [Expecta setAsynchronousTestTimeout:3.0];
    
    __block id blockResponseObject = nil;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/delay/1" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        blockResponseObject = responseObject;
    } failure:nil];
    
    //AFHTTPOperation currently does not have a default response serializer
    [operation setResponseSerializer:[AFHTTPResponseSerializer serializer]];
    
    [operation start];
    expect([operation isExecuting]).will.beTruthy();
    
    [operation pause];
    expect([operation isPaused]).will.beTruthy();
    
    [operation resume];
    expect([operation isExecuting]).will.beTruthy();
    expect([operation isFinished]).will.beTruthy();
    expect(blockResponseObject).willNot.beNil();
}

@end
