//
//  AFJSONRequestOperationTests.m
//  AFNetworking Tests
//
//  Created by Kevin Harwood on 5/16/13.
//  Copyright (c) 2013 AFNetworking. All rights reserved.
//

#import "AFNetworkingTests.h"
#import "AFURLConnectionOperation.h"
#import "AFTestURLProtocol.h"
#import "OCMock.h"

@interface AFURLConnectionOperationTests : SenTestCase

@property (readwrite, nonatomic, strong) NSURL *baseURL;

@end



@implementation AFURLConnectionOperationTests
@synthesize baseURL = _baseURL;

- (void)setUp {
    self.baseURL = [NSURL URLWithString:AFNetworkingTestsBaseURLString];
}

- (void)testThatAFURLConnectionOperationInvokesWillSendRequestForAuthenticationChallengeBlock {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/path" relativeToURL:self.baseURL]];
    AFURLConnectionOperation *operation = [[AFURLConnectionOperation alloc] initWithRequest:request];
    
    __block BOOL willSendRequestForAuthenticationChallengeBlockInvoked = NO;
    [operation setWillSendRequestForAuthenticationChallengeBlock:^(NSURLConnection *connection, NSURLAuthenticationChallenge *challenge) {
        willSendRequestForAuthenticationChallengeBlockInvoked = YES;
    }];
    
    [AFTestURLProtocol matchURL:request.URL withCallback:^id(AFTestURLProtocol *protocol) {
        id mockedProtocol = [OCMockObject partialMockForObject:protocol];
        
        void(^startOperation)(NSInvocation *invocation) = ^(NSInvocation *invocation) {
            __unsafe_unretained AFTestURLProtocol *protocol = nil;
            [invocation getArgument:&protocol atIndex:0];
            
            NSURLProtectionSpace *protectionSpace = [[NSURLProtectionSpace alloc] initWithHost:request.URL.host port:request.URL.port.integerValue protocol:request.URL.scheme realm:nil authenticationMethod:NSURLAuthenticationMethodDefault];
            NSURLAuthenticationChallenge *authenticationChallenge = [[NSURLAuthenticationChallenge alloc] initWithProtectionSpace:protectionSpace proposedCredential:nil previousFailureCount:0 failureResponse:nil error:nil sender:protocol];
            [protocol.client URLProtocol:protocol didReceiveAuthenticationChallenge:authenticationChallenge];
        };
        [[[mockedProtocol stub] andDo:startOperation] startLoading];
        
        return mockedProtocol;
    }];
    
    [operation start];
    expect(willSendRequestForAuthenticationChallengeBlockInvoked).will.beTruthy();
    
    [operation cancel];
}

@end
