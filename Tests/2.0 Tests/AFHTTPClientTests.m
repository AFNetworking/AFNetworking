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

- (void)testThatTaskCanBeSuspended {
    [Expecta setAsynchronousTestTimeout:3.0];
    NSURLSessionTask * task = [self.client
                               GET:@"/delay/1"
                               parameters:nil
                               success:nil
                               failure:nil];
    
    expect(task.state == NSURLSessionTaskStateRunning).will.beTruthy();
    [task suspend];
    expect(task.state == NSURLSessionTaskStateSuspended).will.beTruthy();
    [task cancel];
}


- (void)testThatSuspendedTaskCanBeResumed {
    [Expecta setAsynchronousTestTimeout:3.0];
    NSURLSessionTask * task = [self.client
                               GET:@"/delay/1"
                               parameters:nil
                               success:nil
                               failure:nil];
    
    expect(task.state == NSURLSessionTaskStateRunning).will.beTruthy();
    [task suspend];
    expect(task.state == NSURLSessionTaskStateSuspended).will.beTruthy();
    [task resume];
    expect(task.state == NSURLSessionTaskStateRunning).will.beTruthy();
    [task cancel];
}

- (void)testThatSuspendedTaskCanBeCompleted {
    [Expecta setAsynchronousTestTimeout:3.0];
    NSURLSessionTask * task = [self.client
                               GET:@"/delay/1"
                               parameters:nil
                               success:nil
                               failure:nil];
    
    expect(task.state == NSURLSessionTaskStateRunning).will.beTruthy();
    [task suspend];
    expect(task.state == NSURLSessionTaskStateSuspended).will.beTruthy();
    [task resume];
    expect(task.state == NSURLSessionTaskStateCompleted).will.beTruthy();
}

- (void)testThatRedirectBlockIsCalledWhen302IsEncountered {
    __block BOOL success;
    
    [Expecta setAsynchronousTestTimeout:3.0];
    NSURLSessionTask * dataTask = [self.client
                                   GET:@"/redirect/1"
                                   parameters:nil
                                   success:nil
                                   failure:nil];
    [self.client
     setTaskWillPerformHTTPRedirectionBlock:^NSURLRequest *(NSURLSession *session, NSURLSessionTask *task, NSURLResponse *response, NSURLRequest *request) {
         if(response){
             success = YES;
         }
         return request;
     }];
    
    expect(dataTask.state == NSURLSessionTaskStateCompleted).will.beTruthy();
    expect(success).will.beTruthy();
    [self.client setTaskWillPerformHTTPRedirectionBlock:nil];
}

- (void)testThatRedirectBlockIsCalledMultipleTimesWhenMultiple302sAreEncountered {
    [Expecta setAsynchronousTestTimeout:5.0];
    __block NSInteger numberOfRedirects = 0;
    NSURLSessionTask * dataTask = [self.client
                                   GET:@"/redirect/5"
                                   parameters:nil
                                   success:nil
                                   failure:nil];
    [self.client
     setTaskWillPerformHTTPRedirectionBlock:^NSURLRequest *(NSURLSession *session, NSURLSessionTask *task, NSURLResponse *response, NSURLRequest *request) {
         if(response){
            numberOfRedirects++;
         }
         return request;
     }];
    
    expect(dataTask.state == NSURLSessionTaskStateCompleted).will.beTruthy();
    expect(numberOfRedirects).will.equal(5);
    [self.client setTaskWillPerformHTTPRedirectionBlock:nil];
}

@end
