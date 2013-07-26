//
//  AFHTTPClientTests.m
//  AFNetworking Tests
//
//  Created by Kevin Harwood on 7/26/13.
//  Copyright (c) 2013 AFNetworking. All rights reserved.
//

#import "AFNetworkingTests.h"

@interface AFHTTPClientTests : XCTestCase
@property (readwrite, nonatomic, strong) AFHTTPClient *client;
@end

@implementation AFHTTPClientTests

- (void)setUp {
    self.client = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:AFNetworkingTestsBaseURLString]];
}

- (void)testReachabilityStatus {
    [Expecta setAsynchronousTestTimeout:5.0];
    
    expect(self.client.networkReachabilityStatus).to.equal(@(AFNetworkReachabilityStatusUnknown));
    
    __block AFNetworkReachabilityStatus reachabilityStatus = self.client.networkReachabilityStatus;
    
    [self.client setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        reachabilityStatus = status;
    }];
    
    expect(reachabilityStatus).will.equal(@(AFNetworkReachabilityStatusReachableViaWiFi));
}

- (void)testThatTaskInvokesFailureCompletionBlockWithErrorOnFailure{
    [Expecta setAsynchronousTestTimeout:5.0];
    __block NSError *blockError = nil;
    
    NSURLSessionDataTask * task = [self.client
                                   GET:@"status/404"
                                   parameters:nil
                                   success:nil
                                   failure:^(NSError *error) {
                                       blockError = error;
                                   }];
    
    expect(task.state == NSURLSessionTaskStateCompleted).will.beTruthy();
    expect(blockError).willNot.beNil();
}

- (void)testThatTaskInvokesSuccessCompletionBlockWithResponseObjectOnSuccess {
    [Expecta setAsynchronousTestTimeout:5.0];
    __block id blockResponseObject = nil;
    
    NSURLSessionDataTask * task = [self.client
                                   GET:@"/get"
                                   parameters:nil
                                   success:^(NSHTTPURLResponse *response, id responseObject) {
                                       blockResponseObject = responseObject;
                                   }
                                   failure:nil];

    expect(task.state == NSURLSessionTaskStateCompleted).will.beTruthy();
    expect(blockResponseObject).willNot.beNil();
}

- (void)testThatCancellationOfTaskSetsError {
    [Expecta setAsynchronousTestTimeout:5.0];
    __block NSError * blockError;
    NSURLSessionDataTask * task = [self.client
                                   GET:@"/delay/5"
                                   parameters:nil
                                   success:nil
                                   failure:^(NSError *error) {
                                       blockError = error;
                                   }];
    expect(task.state == NSURLSessionTaskStateRunning).will.beTruthy();
    [task cancel];
    expect(task.state == NSURLSessionTaskStateCompleted).will.beTruthy();
    expect(blockError).willNot.beNil();
    expect(blockError.code).to.equal(NSURLErrorCancelled);
}

@end
