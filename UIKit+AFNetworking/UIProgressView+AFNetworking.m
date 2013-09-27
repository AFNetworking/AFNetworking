// UIProgressView+AFNetworking.m
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

#import "UIProgressView+AFNetworking.h"

#import <objc/runtime.h>

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)

#import "AFURLConnectionOperation.h"

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
#import "AFURLSessionManager.h"
#endif

static void * AFTaskCountOfBytesSentContext = &AFTaskCountOfBytesSentContext;
static void * AFTaskCountOfBytesReceivedContext = &AFTaskCountOfBytesReceivedContext;

static char kAFUploadProgressAnimated;
static char kAFDownloadProgressAnimated;

@interface AFURLConnectionOperation (_UIProgressView)
@property (readwrite, nonatomic, copy) void (^af_uploadProgress)(NSUInteger bytes, long long totalBytes, long long totalBytesExpected);
@property (readwrite, nonatomic, assign, setter = af_setUploadProgressAnimated:) BOOL af_uploadProgressAnimated;

@property (readwrite, nonatomic, copy) void (^af_downloadProgress)(NSUInteger bytes, long long totalBytes, long long totalBytesExpected);
@property (readwrite, nonatomic, assign, setter = af_setDownloadProgressAnimated:) BOOL af_downloadProgressAnimated;
@end

@implementation AFURLConnectionOperation (_UIProgressView)
@dynamic af_uploadProgress;
@dynamic af_uploadProgressAnimated;

@dynamic af_downloadProgress;
@dynamic af_downloadProgressAnimated;
@end

#pragma mark -

@implementation UIProgressView (AFNetworking)

- (BOOL)af_uploadProgressAnimated {
    return [(NSNumber *)objc_getAssociatedObject(self, &kAFUploadProgressAnimated) boolValue];
}

- (void)af_setUploadProgressAnimated:(BOOL)animated {
    objc_setAssociatedObject(self, &kAFUploadProgressAnimated, @(animated), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)af_downloadProgressAnimated {
    return [(NSNumber *)objc_getAssociatedObject(self, &kAFDownloadProgressAnimated) boolValue];
}

- (void)af_setDownloadProgressAnimated:(BOOL)animated {
    objc_setAssociatedObject(self, &kAFDownloadProgressAnimated, @(animated), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark -

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000

- (void)setProgressWithUploadProgressOfTask:(NSURLSessionUploadTask *)task
                                   animated:(BOOL)animated
{
    [task addObserver:self forKeyPath:@"state" options:0 context:AFTaskCountOfBytesSentContext];
    [task addObserver:self forKeyPath:@"countOfBytesSent" options:0 context:AFTaskCountOfBytesSentContext];

    [self af_setUploadProgressAnimated:animated];
}

- (void)setProgressWithDownloadProgressOfTask:(NSURLSessionDownloadTask *)task
                                     animated:(BOOL)animated
{
    [task addObserver:self forKeyPath:@"state" options:0 context:AFTaskCountOfBytesReceivedContext];
    [task addObserver:self forKeyPath:@"countOfBytesReceived" options:0 context:AFTaskCountOfBytesReceivedContext];

    [self af_setDownloadProgressAnimated:animated];
}

#endif

#pragma mark -

- (void)setProgressWithUploadProgressOfOperation:(AFURLConnectionOperation *)operation
                                        animated:(BOOL)animated
{
    __weak __typeof(self)weakSelf = self;
    void (^original)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) = [operation.af_uploadProgress copy];
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        if (original) {
            original(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (totalBytesExpectedToWrite > 0) {
                [weakSelf setProgress:(totalBytesWritten / (totalBytesExpectedToWrite * 1.0f)) animated:animated];
            }
        });
    }];
}

- (void)setProgressWithDownloadProgressOfOperation:(AFURLConnectionOperation *)operation
                                          animated:(BOOL)animated
{
    __weak __typeof(self)weakSelf = self;
    void (^original)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) = [operation.af_downloadProgress copy];
    [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        if (original) {
            original(bytesRead, totalBytesRead, totalBytesExpectedToRead);
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (totalBytesExpectedToRead > 0) {
                [weakSelf setProgress:(totalBytesRead / (totalBytesExpectedToRead  * 1.0f)) animated:animated];
            }
        });
    }];
}

#pragma mark - NSKeyValueObserving

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(__unused NSDictionary *)change
                       context:(void *)context
{
    if (context == AFTaskCountOfBytesSentContext || context == AFTaskCountOfBytesReceivedContext) {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(countOfBytesSent))]) {
            if ([object countOfBytesExpectedToSend] > 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setProgress:[object countOfBytesSent] / ([object countOfBytesExpectedToSend] * 1.0f) animated:self.af_uploadProgressAnimated];
                });
            }
        }

        if ([keyPath isEqualToString:NSStringFromSelector(@selector(countOfBytesReceived))]) {
            if ([object countOfBytesExpectedToReceive] > 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setProgress:[object countOfBytesReceived] / ([object countOfBytesExpectedToReceive] * 1.0f) animated:self.af_downloadProgressAnimated];
                });
            }
        }

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(state))]) {
            if ([(NSURLSessionTask *)object state] == NSURLSessionTaskStateCompleted) {
                @try {
                    [object removeObserver:self forKeyPath:NSStringFromSelector(@selector(state))];

                    if (context == AFTaskCountOfBytesSentContext) {
                        [object removeObserver:self forKeyPath:NSStringFromSelector(@selector(countOfBytesSent))];
                    }

                    if (context == AFTaskCountOfBytesReceivedContext) {
                        [object removeObserver:self forKeyPath:NSStringFromSelector(@selector(countOfBytesSent))];
                    }
                }
                @catch (NSException * __unused exception) {}
            }
        }
#endif
    }
}

@end

#endif
