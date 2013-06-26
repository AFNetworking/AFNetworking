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

@implementation UIActivityIndicatorView (AFNetworking)

- (void)setAnimatingWithStateOfOperation:(AFURLConnectionOperation *)operation {
    [operation addObserver:self forKeyPath:@"isExecuting" options:0 context:nil];
    [operation addObserver:self forKeyPath:@"isFinished" options:0 context:nil];
}

- (void)setAnimatingWithStateOfTask:(NSURLSessionTask *)task {
    [task addObserver:self forKeyPath:@"state" options:0 context:nil];
}

#pragma mark NSKeyValueObserving

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // TODO invoke supersequent implementation

    if ([object isKindOfClass:[NSURLSessionTask class]]) {
        if ([keyPath isEqualToString:@"state"]) {
            [object state] == NSURLSessionTaskStateRunning ? [self startAnimating] : [self stopAnimating];
        }

        if ([object state] == NSURLSessionTaskStateCompleted) {
            [object removeObserver:self];
        }
    } else if ([object isKindOfClass:[AFURLConnectionOperation class]]) {
        if ([keyPath isEqualToString:@"isExecuting"]) {
            [object isExecuting] ? [self startAnimating] : [self stopAnimating];
        }

        if ([object isFinished]) {
            [object removeObserver:self];
        }
    }
}

@end
