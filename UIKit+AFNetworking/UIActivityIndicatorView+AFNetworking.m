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
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    [notificationCenter removeObserver:self name:AFNetworkingOperationDidStartNotification object:nil];
    [notificationCenter removeObserver:self name:AFNetworkingOperationDidFinishNotification object:nil];

    if (![operation isFinished]) {
        if ([operation isExecuting]) {
            [self startAnimating];
        } else {
            [self stopAnimating];
        }

        NSOperationQueue *operationQueue = [NSOperationQueue mainQueue];

        [notificationCenter addObserverForName:AFNetworkingOperationDidStartNotification object:operation queue:operationQueue usingBlock:^(NSNotification *notification) {
            [self startAnimating];
        }];

        [notificationCenter addObserverForName:AFNetworkingOperationDidFinishNotification object:operation queue:operationQueue usingBlock:^(NSNotification *notification) {
            [self stopAnimating];

            [[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingTaskDidFinishNotification object:nil];
        }];
    }
}

- (void)setAnimatingWithStateOfTask:(NSURLSessionTask *)task {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    [notificationCenter removeObserver:self name:AFNetworkingTaskDidStartNotification object:nil];
    [notificationCenter removeObserver:self name:AFNetworkingTaskDidSuspendNotification object:nil];
    [notificationCenter removeObserver:self name:AFNetworkingTaskDidFinishNotification object:nil];

    if (task.state != NSURLSessionTaskStateCompleted) {
        if (task.state == NSURLSessionTaskStateRunning) {
            [self startAnimating];
        } else {
            [self stopAnimating];
        }

        NSOperationQueue *operationQueue = [NSOperationQueue mainQueue];

        [notificationCenter addObserverForName:AFNetworkingTaskDidStartNotification object:task queue:operationQueue usingBlock:^(NSNotification *notification) {
            [self startAnimating];
        }];

        [notificationCenter addObserverForName:AFNetworkingTaskDidFinishNotification object:task queue:operationQueue usingBlock:^(NSNotification *notification) {
            [self stopAnimating];
        }];

        [notificationCenter addObserverForName:AFNetworkingTaskDidSuspendNotification object:task queue:operationQueue usingBlock:^(NSNotification *notification) {
            [self stopAnimating];

            [[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingTaskDidFinishNotification object:nil];
        }];
    }
}

@end
