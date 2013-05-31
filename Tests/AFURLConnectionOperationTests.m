// AFJSONRequestOperationTests.m
//
// Copyright (c) 2013 AFNetworking (http://afnetworking.com)
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
#import "AFURLConnectionOperation.h"
#import "AFTestURLProtocol.h"

@interface AFURLConnectionOperationTests : SenTestCase
@property (readwrite, nonatomic, strong) NSURL *baseURL;
@end

@implementation AFURLConnectionOperationTests
@synthesize baseURL = _baseURL;

- (void)setUp {
    self.baseURL = [NSURL URLWithString:AFNetworkingTestsBaseURLString];
}

#pragma mark -

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
