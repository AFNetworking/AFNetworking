// AFTestURLProtocol.m
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

#import "AFTestURLProtocol.h"

typedef id (^AFTestURLProtocolInitializationCallback)(AFTestURLProtocol *protocol);

static NSURL * _matchingURL = nil;
static AFTestURLProtocolInitializationCallback _initializationCallback = nil;

@implementation AFTestURLProtocol

+ (void)load {
    [NSURLProtocol registerClass:[AFTestURLProtocol class]];
}

+ (void)matchURL:(NSURL *)URL
    withCallback:(id(^)(AFTestURLProtocol *protocol))callback
{
    _matchingURL = URL;
    _initializationCallback = callback;
}

#pragma mark - NSURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    return [request.URL isEqual:_matchingURL] && _initializationCallback;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b {
    return NO;
}

- (id)initWithRequest:(NSURLRequest *)request
       cachedResponse:(NSCachedURLResponse *)cachedResponse
               client:(id <NSURLProtocolClient>)client
{
    NSParameterAssert(_initializationCallback);
    
    self = [super initWithRequest:request cachedResponse:cachedResponse client:client];
    if (!self) {
        return nil;
    }

    self = _initializationCallback(self);

    _matchingURL = nil;
    _initializationCallback = nil;

    return self;
}

- (void)startLoading {}

- (void)stopLoading {}

#pragma mark - NSURLAuthenticationChallengeSender

- (void)cancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {}

- (void)continueWithoutCredentialForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {}

- (void)useCredential:(NSURLCredential *)credential
forAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {}

- (void)performDefaultHandlingForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {}

- (void)rejectProtectionSpaceAndContinueWithChallenge:(NSURLAuthenticationChallenge *)challenge {}

@end
