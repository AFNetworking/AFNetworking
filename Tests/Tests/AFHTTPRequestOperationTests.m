// AFHTTPRequestOperationTests.m
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

#import "AFHTTPRequestOperation.h"

@interface AFHTTPRequestOperationTests : AFTestCase
@end

@implementation AFHTTPRequestOperationTests

// FLAKY: This test does not deterministically fail when the AFHTTPRequestOperation logic is incorrect.
// See comments inside for details.
// When this test does fail, most tests in this class will also fail, since the network thread is stalled.
// The tests should be better encapsulated - setUp and tearDown should reset the state of the network thread.
- (void)testPauseResumeStallsNetworkThread {
    [Expecta setAsynchronousTestTimeout:5.0];

    __block id blockResponseObject = nil;
    __block id blockError = nil;

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/delay/1" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        blockResponseObject = responseObject;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        blockError = error;
    }];

    // FLAKY: For this test to correctly fail, 'pause' must happen on the main thread before the network thread has run the logic of 'start'.
    // The non-intrusive fix to this is to create fine grained control over the starting/stopping of the network thread, rather than having the network thread continually process events in the background.

    // Start, and then immediately pause the connection.
    // The pause should correctly reset the state of the operation.
    // This test fails when pause incorrectly resets the state of the operation.
    [operation start];
    [operation pause];
    expect([operation isPaused]).will.beTruthy();

    // Resume the operation.
    [operation resume];
    expect([operation isExecuting]).will.beTruthy();
    expect([operation isFinished]).will.beTruthy();
    expect(blockError).will.beNil();
    expect(blockResponseObject).willNot.beNil();

    // The first operation completed, but the network thread is now in an infinite loop.
    // Future requests should not work.
    blockResponseObject = nil;
    AFHTTPRequestOperation *operation2 = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation2 setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        blockResponseObject = responseObject;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        blockError = error;
    }];

    // The network thread is stalled, so this operation could not succeed.
    [operation2 start];
    expect(blockError).will.beNil();
    expect(blockResponseObject).willNot.beNil();
}

- (void)testThatOperationInvokesSuccessCompletionBlockWithResponseObjectOnSuccess {
    __block id blockResponseObject = nil;
    __block id blockError = nil;

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/get" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];

    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        blockResponseObject = responseObject;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        blockError = error;
    }];

    [operation start];

    expect([operation isFinished]).will.beTruthy();
    expect(blockError).will.beNil();
    expect(blockResponseObject).willNot.beNil();
}

- (void)testThatOperationInvokesSuccessCompletionBlockOn204 {
    __block id blockResponseObject = nil;
    __block NSError *blockError = nil;

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/status/204" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];

    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        blockResponseObject = responseObject;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        blockError = error;
    }];

    [operation start];

    expect([operation isFinished]).will.beTruthy();
    expect(blockError).will.beNil();
    expect(blockResponseObject).will.equal([NSData data]);
}

- (void)testThatOperationInvokesFailureCompletionBlockWithErrorOnFailure {
    __block NSError *blockError = nil;

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/status/404" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];

    [operation setCompletionBlockWithSuccess:nil failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        blockError = error;
    }];

    [operation start];
    expect([operation isFinished]).will.beTruthy();
    expect(blockError).willNot.beNil();
}

- (void)testThatCancellationOfRequestOperationSetsError {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/delay/5" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];

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

- (void)testThatCancellationOfRequestBeforeStartingRequestSetsError {
    __block NSError *blockError = nil;

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/delay/5" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];

    [operation setCompletionBlockWithSuccess:nil failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        blockError = error;
    }];

    [operation cancel];
    [operation start];

    expect([operation isCancelled]).will.beTruthy();
    expect([operation isFinished]).will.beTruthy();
    expect([operation isExecuting]).will.beFalsy();

    expect(operation.error).willNot.beNil();
    expect(blockError).willNot.beNil();
    expect(blockError.code).will.equal(NSURLErrorCancelled);
}

- (void)testThatCancellationOfRequestBeforeStartingRequestSetsErrorInvokesFailureCompletionBlock {
    __block NSError *blockError = nil;

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/delay/5" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];

    [operation setCompletionBlockWithSuccess:nil failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        blockError = error;
    }];

    [operation cancel];
    [operation start];

    expect(operation.error).willNot.beNil();
    expect(blockError).willNot.beNil();
    expect(blockError.code).will.equal(NSURLErrorCancelled);
}

- (void)testThat500StatusCodeInvokesFailureCompletionBlockWithErrorOnFailure {
    __block NSError *blockError = nil;

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/status/500" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];

    [operation setCompletionBlockWithSuccess:nil failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        blockError = error;
    }];

    [operation start];
    expect([operation isFinished]).will.beTruthy();
    expect(blockError).willNot.beNil();
}

- (void)testThatRedirectBlockIsCalledWhen302IsEncountered {
    __block BOOL success;
    __block NSError *blockError = nil;

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/redirect/1" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];

    [operation setCompletionBlockWithSuccess:nil failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        blockError = error;
    }];
    [operation setRedirectResponseBlock:^NSURLRequest *(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *redirectResponse) {
        if(redirectResponse){
            success = YES;
        }

        return request;
    }];

    [operation start];
    expect([operation isFinished]).will.beTruthy();
    expect(blockError).will.beNil();
    expect(success).will.beTruthy();
}

- (void)testThatRedirectBlockIsCalledMultipleTimesWhenMultiple302sAreEncountered {
    [Expecta setAsynchronousTestTimeout:5.0];
    __block NSInteger numberOfRedirects = 0;
    __block NSError *blockError = nil;

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/redirect/5" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];

    [operation setCompletionBlockWithSuccess:nil failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        blockError = error;
    }];
    [operation setRedirectResponseBlock:^NSURLRequest *(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *redirectResponse) {
        if(redirectResponse){
            numberOfRedirects++;
        }

        return request;
    }];

    [operation start];
    expect([operation isFinished]).will.beTruthy();
    expect(blockError).will.beNil();
    expect(numberOfRedirects).will.equal(5);
}

#pragma mark - Pause

- (void)testThatOperationCanBePaused {
    [Expecta setAsynchronousTestTimeout:3.0];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/delay/1" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];

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
    __block id blockError = nil;

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/delay/1" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        blockResponseObject = responseObject;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        blockError = error;
    }];

    [operation start];
    expect([operation isExecuting]).will.beTruthy();

    [operation pause];
    expect([operation isPaused]).will.beTruthy();

    [operation resume];
    expect([operation isExecuting]).will.beTruthy();
    expect([operation isFinished]).will.beTruthy();
    expect(blockError).will.beNil();
    expect(blockResponseObject).willNot.beNil();
}

- (void)testThatOperationPostsDidStartNotificationWhenStarted {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/get" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];

    __block BOOL notificationFound;

    id observer = [[NSNotificationCenter defaultCenter] addObserverForName:AFNetworkingOperationDidStartNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        if([[[note object] request] isEqual:operation.request]){
            notificationFound = YES;
        }
    }];

    [operation start];
    expect(notificationFound).will.beTruthy();

    [[NSNotificationCenter defaultCenter] removeObserver:observer];
}

- (void)testThatOperationPostsDidFinishNotificationWhenFinished {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/get" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];

    __block BOOL notificationFound;

    id observer = [[NSNotificationCenter defaultCenter] addObserverForName:AFNetworkingOperationDidFinishNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        if([[[note object] request] isEqual:operation.request]){
            notificationFound = YES;
        }
    }];

    [operation start];
    expect(notificationFound).will.beTruthy();

    [[NSNotificationCenter defaultCenter] removeObserver:observer];
}

-(void)testThatCompletionBlockForBatchRequestsIsFiredAfterAllOperationCompletionBlocks {
    __block BOOL firstBlock = NO;
    __block BOOL secondBlock = NO;
    __block id firstBlockError = nil;
    __block id secondBlockError = nil;

    NSURLRequest *request1 = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/get" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation1 = [[AFHTTPRequestOperation alloc] initWithRequest:request1];
    [operation1 setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        firstBlock = YES;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        firstBlockError = error;
    }];
    [operation1 setResponseSerializer:[AFHTTPResponseSerializer serializer]];

    NSURLRequest *request2 = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/delay/1" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation2 = [[AFHTTPRequestOperation alloc] initWithRequest:request2];
    [operation2 setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        secondBlock = YES;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        secondBlockError = error;
    }];
    [operation2 setResponseSerializer:[AFHTTPResponseSerializer serializer]];

    __block BOOL completionBlockFiredAfterOtherBlocks = NO;
    NSArray *batchRequests = [AFURLConnectionOperation batchOfRequestOperations:@[operation1, operation2] progressBlock:nil completionBlock:^(NSArray *operations) {
        if (firstBlock && secondBlock) {
            completionBlockFiredAfterOtherBlocks = YES;
        }
    }];

    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperations:batchRequests waitUntilFinished:NO];

    expect(firstBlockError).will.beNil();
    expect(secondBlockError).will.beNil();
    expect(completionBlockFiredAfterOtherBlocks).will.beTruthy();
}

- (void)testThatOperationInvokesFailureCompletionBlockWithErrorOnWritingStreamFailure {
    __block NSError *blockError;

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/get" relativeToURL:self.baseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];

    NSError *streamError = [NSError errorWithDomain:NSStreamSocketSSLErrorDomain code:0 userInfo:nil];

    [operation setOutputStream:({
        id mockStream = [OCMockObject mockForClass:[NSOutputStream class]];
        [[[mockStream stub] andReturn:streamError] streamError];
        BOOL no = NO;
        [[[mockStream stub] andReturnValue:OCMOCK_VALUE(no)] hasSpaceAvailable];

        // "Note that currently partial mocks cannot be created for instances of toll-free bridged classes". Thus, we have to fully mock it
        [[mockStream stub] scheduleInRunLoop:OCMOCK_ANY forMode:OCMOCK_ANY];
        [[mockStream stub] open];
        [[mockStream stub] close];

        mockStream;
    })];

    [operation setCompletionBlockWithSuccess:nil failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        blockError = error;
    }];

    [operation start];
    expect([operation isFinished]).will.beTruthy();
    expect(blockError).will.equal(streamError);
}

- (void)testThatOperationInvokesSuccessCompletionBlockForHTTPSRequest {
    __block id blockResponseObject = nil;
    __block id blockError = nil;

    NSURL *secureBaseURL = [NSURL URLWithString:[self.baseURL.absoluteString stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"]];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/get" relativeToURL:secureBaseURL]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];

    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        blockResponseObject = responseObject;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        blockError = error;
    }];

    [operation start];

    expect([operation isFinished]).will.beTruthy();
    expect(blockError).will.beNil();
    expect(blockResponseObject).willNot.beNil();
}

@end
