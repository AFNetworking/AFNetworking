// UIActivityIndicatorView+AFNetworking.m
//
// Copyright (c) 2013-2015 AFNetworking (http://afnetworking.com)
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

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)

#import "AFHTTPRequestOperation.h"

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
#import "AFURLSessionManager.h"
#endif

@implementation UIActivityIndicatorView (AFNetworking)

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
- (void)setAnimatingWithStateOfTask:(NSURLSessionTask *)task {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    [notificationCenter removeObserver:self name:AFNetworkingTaskDidResumeNotification object:nil];
    [notificationCenter removeObserver:self name:AFNetworkingTaskDidSuspendNotification object:nil];
    [notificationCenter removeObserver:self name:AFNetworkingTaskDidCompleteNotification object:nil];

    if (task) {
        if (task.state != NSURLSessionTaskStateCompleted) {
            if (task.state == NSURLSessionTaskStateRunning) {
                [self startAnimating];
            } else {
                [self stopAnimating];
            }

            [notificationCenter addObserver:self selector:@selector(af_startAnimating) name:AFNetworkingTaskDidResumeNotification object:task];
            [notificationCenter addObserver:self selector:@selector(af_stopAnimating) name:AFNetworkingTaskDidCompleteNotification object:task];
            [notificationCenter addObserver:self selector:@selector(af_stopAnimating) name:AFNetworkingTaskDidSuspendNotification object:task];
        }
    }
}
#endif

#pragma mark -

- (void)setAnimatingWithStateOfOperation:(AFURLConnectionOperation *)operation {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    [notificationCenter removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
    [notificationCenter removeObserver:self name:AFNetworkingOperationDidFinishNotification object:nil];

    if (operation) {
        if (![operation isFinished]) {
            if ([operation isExecuting]) {
                [self startAnimating];
            } else {
                [self stopAnimating];
            }

            [notificationCenter addObserver:self selector:@selector(af_startAnimating) name:AFNetworkingOperationDidStartNotification object:operation];
            [notificationCenter addObserver:self selector:@selector(af_stopAnimating) name:AFNetworkingOperationDidFinishNotification object:operation];
        }
    }
}

#pragma mark -

- (void)af_startAnimating {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self startAnimating];
    });
}

- (void)af_stopAnimating {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self stopAnimating];
    });
}

@end

#endif
