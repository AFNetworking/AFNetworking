// AFTestURLProtocol.m
//
// Copyright (c) 2011 Gowalla (http://gowalla.com/)
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

typedef id(^AFTestURLProtocolInitializationCallback)(AFTestURLProtocol *protocol);
static NSURL *matchingURL = nil;
static AFTestURLProtocolInitializationCallback initializationCallback = NULL;



@implementation AFTestURLProtocol

+ (void)matchURL:(NSURL *)URL withCallback:(id(^)(AFTestURLProtocol *protocol))callback {
    matchingURL = URL;
    initializationCallback = callback;
}

+ (void)load {
    [NSURLProtocol registerClass:[AFTestURLProtocol class]];
}

#pragma mark - NSURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    return [request.URL isEqual:matchingURL] && initializationCallback;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b {
    return NO;
}

- (id)initWithRequest:(NSURLRequest *)request cachedResponse:(NSCachedURLResponse *)cachedResponse client:(id<NSURLProtocolClient>)client {
    NSParameterAssert(initializationCallback);
    
    if (self = [super initWithRequest:request cachedResponse:cachedResponse client:client]) {
        self = initializationCallback(self);
        
        matchingURL = nil;
        initializationCallback = NULL;
    }
    return self;
}

- (void)startLoading {
    
}

- (void)stopLoading {
    
}

#pragma mark - NSURLAuthenticationChallengeSender

- (void)useCredential:(NSURLCredential *)credential forAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
}

- (void)continueWithoutCredentialForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
}

- (void)cancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
}

- (void)performDefaultHandlingForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
}

- (void)rejectProtectionSpaceAndContinueWithChallenge:(NSURLAuthenticationChallenge *)challenge {
    
}

@end
