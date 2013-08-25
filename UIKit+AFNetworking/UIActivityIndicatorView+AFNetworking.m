// UIActivityIndicatorView+AFNetworking.m
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

#import "UIActivityIndicatorView+AFNetworking.h"

#import "AFURLConnectionOperation.h"
#import "AFURLSessionManager.h"

@implementation UIActivityIndicatorView (AFNetworking)

- (void)setAnimatingWithStateOfOperation:(AFURLConnectionOperation *)operation {
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self selector:@selector(af_networkRequestDidStart:) name:AFNetworkingOperationDidStartNotification object:operation];
    [defaultCenter addObserver:self selector:@selector(af_networkRequestDidFinish:) name:AFNetworkingOperationDidFinishNotification object:operation];
    
    if (operation.isExecuting) {
        [self startAnimating];
    } else {
        [self stopAnimating];
    }
}

- (void)setAnimatingWithStateOfTask:(NSURLSessionTask *)task {
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self selector:@selector(af_networkRequestDidStart:) name:AFNetworkingTaskDidStartNotification object:task];
    [defaultCenter addObserver:self selector:@selector(af_networkRequestDidSuspend:) name:AFNetworkingTaskDidSuspendNotification object:task];
    [defaultCenter addObserver:self selector:@selector(af_networkRequestDidFinish:) name:AFNetworkingTaskDidFinishNotification object:task];
    
    if (task.state == NSURLSessionTaskStateRunning) {
        [self startAnimating];
    } else {
        [self stopAnimating];
    }
}

#pragma mark - NSNotification

- (void)af_networkRequestDidStart:(NSNotification *)notification {
    [self startAnimating];
}

- (void)af_networkRequestDidSuspend:(NSNotification *)notification {
    [self stopAnimating];
}

- (void)af_networkRequestDidFinish:(NSNotification *)notification {
    [self stopAnimating];
    
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter removeObserver:self name:AFNetworkingOperationDidStartNotification object:[notification object]];
    [defaultCenter removeObserver:self name:AFNetworkingOperationDidFinishNotification object:[notification object]];
    
    [defaultCenter removeObserver:self name:AFNetworkingTaskDidStartNotification object:[notification object]];
    [defaultCenter removeObserver:self name:AFNetworkingTaskDidSuspendNotification object:[notification object]];
    [defaultCenter removeObserver:self name:AFNetworkingTaskDidFinishNotification object:[notification object]];
}

@end
