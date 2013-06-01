// AFMockURLProtocol.m
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

#import "AFMockURLProtocol.h"

typedef void (^AFTestURLProtocolInitializationCallback)(AFMockURLProtocol *protocol);

static volatile NSURL * _matchingURL = nil;
static volatile AFTestURLProtocolInitializationCallback _initializationCallback = nil;

@implementation AFMockURLProtocol

+ (void)load {
    [NSURLProtocol registerClass:[AFMockURLProtocol class]];
}

+ (void)handleNextRequestForURL:(NSURL *)URL
                     usingBlock:(void (^)(AFMockURLProtocol <AFMockURLProtocolProxy> * protocol))block;
{
    _matchingURL = URL;
    _initializationCallback = block;
}

#pragma mark - NSURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    return [request.URL isEqual:_matchingURL] && _initializationCallback;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a
                       toRequest:(NSURLRequest *)b
{
    return NO;
}

- (id)initWithRequest:(NSURLRequest *)request
       cachedResponse:(NSCachedURLResponse *)cachedResponse
               client:(id <NSURLProtocolClient>)client
{
    self = [super initWithRequest:request cachedResponse:cachedResponse client:client];
    if (!self) {
        return nil;
    }

    if (_initializationCallback) {
        self = [OCMockObject partialMockForObject:self];

        _initializationCallback(self);
    }

    _initializationCallback = nil;
    _matchingURL = nil;

    return self;
}

- (void)startLoading {}

- (void)stopLoading {}

#pragma mark - NSURLAuthenticationChallengeSender

- (void)cancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    [self doesNotRecognizeSelector:_cmd];
}

- (void)continueWithoutCredentialForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    [self doesNotRecognizeSelector:_cmd];
}

- (void)useCredential:(NSURLCredential *)credential
forAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    [self doesNotRecognizeSelector:_cmd];
}

- (void)performDefaultHandlingForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    [self doesNotRecognizeSelector:_cmd];
}

- (void)rejectProtectionSpaceAndContinueWithChallenge:(NSURLAuthenticationChallenge *)challenge {
    [self doesNotRecognizeSelector:_cmd];
}

@end
