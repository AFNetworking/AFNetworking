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
#import "AFURLConnectionOperation.h"
#import "AFURLSessionManager.h"

@interface AFURLConnectionOperation (_UIProgressView)
@property (readwrite, nonatomic, copy) void (^uploadProgress)(NSUInteger bytes, long long totalBytes, long long totalBytesExpected);
@property (readwrite, nonatomic, copy) void (^downloadProgress)(NSUInteger bytes, long long totalBytes, long long totalBytesExpected);
@end

@implementation AFURLConnectionOperation (_UIProgressView)
@dynamic uploadProgress;
@dynamic downloadProgress;
@end

static void * AFUploadTaskStateChangedContext = &AFUploadTaskStateChangedContext;
static void * AFDownloadTaskStateChangedContext = &AFDownloadTaskStateChangedContext;
static void * AFCountOfBytesSentChangedContext = &AFCountOfBytesSentChangedContext;
static void * AFCountOfBytesReceivedChangedContext = &AFCountOfBytesReceivedChangedContext;

@interface AFTaskProgressObserver : NSObject

- (instancetype)initWithProgressView:(UIProgressView *)progressView;

@property (nonatomic, weak) UIProgressView *progressView;

@end

@implementation AFTaskProgressObserver

- (instancetype)initWithProgressView:(UIProgressView *)progressView {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.progressView = progressView;
    
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(NSURLSessionTask *)task
                        change:(NSDictionary *)change
                       context:(void *)context
{
    float progress = NAN;
    if (context == AFCountOfBytesSentChangedContext && task.countOfBytesExpectedToSend > 0) {
        progress = task.countOfBytesSent / (task.countOfBytesExpectedToSend * 1.0f);
    } else if (context == AFCountOfBytesReceivedChangedContext && task.countOfBytesExpectedToReceive > 0) {
        progress = task.countOfBytesReceived / (task.countOfBytesExpectedToReceive * 1.0f);
    } else if (context == AFUploadTaskStateChangedContext || context == AFDownloadTaskStateChangedContext) {
        if (task.state == NSURLSessionTaskStateCanceling || task.state == NSURLSessionTaskStateCompleted) {
            [task removeObserver:self forKeyPath:@"state" context:context];
            if (context == AFUploadTaskStateChangedContext) {
                [task removeObserver:self forKeyPath:@"countOfBytesSent" context:AFCountOfBytesSentChangedContext];
            } else {
                [task removeObserver:self forKeyPath:@"countOfBytesReceived" context:AFCountOfBytesReceivedChangedContext];
            }
        }
    }
    
    if (!isnan(progress)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressView.progress = progress;
        });
    }
}

@end

#pragma mark -

@interface UIProgressView (_AFNetworking) <NSURLSessionDownloadDelegate>
@end

@implementation UIProgressView (AFNetworking)

static void * AFTaskProgressObserverKey = &AFTaskProgressObserverKey;

- (AFTaskProgressObserver *)af_taskProgressObserver {
    return objc_getAssociatedObject(self, AFTaskProgressObserverKey);
}

- (void)af_setTaskProgressObserver:(AFTaskProgressObserver *)taskProgressObserver {
    objc_setAssociatedObject(self, AFTaskProgressObserverKey, taskProgressObserver, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setProgressWithUploadProgressOfTask:(NSURLSessionUploadTask *)task
                                   animated:(BOOL)animated
{
    AFTaskProgressObserver *taskProgressObserver = [[AFTaskProgressObserver alloc] initWithProgressView:self];
    [self af_setTaskProgressObserver:taskProgressObserver];
    [task addObserver:taskProgressObserver forKeyPath:@"state" options:0 context:AFUploadTaskStateChangedContext];
    [task addObserver:taskProgressObserver forKeyPath:@"countOfBytesSent" options:0 context:AFCountOfBytesSentChangedContext];
}

- (void)setProgressWithDownloadProgressOfTask:(NSURLSessionDownloadTask *)task
                                     animated:(BOOL)animated
{
    AFTaskProgressObserver *taskProgressObserver = [[AFTaskProgressObserver alloc] initWithProgressView:self];
    [self af_setTaskProgressObserver:taskProgressObserver];
    [task addObserver:taskProgressObserver forKeyPath:@"state" options:0 context:AFDownloadTaskStateChangedContext];
    [task addObserver:taskProgressObserver forKeyPath:@"countOfBytesReceived" options:0 context:AFCountOfBytesReceivedChangedContext];
}

- (void)setProgressWithUploadProgressOfOperation:(AFURLConnectionOperation *)operation
                                        animated:(BOOL)animated
{
    __weak __typeof(self)weakSelf = self;
    void (^original)(NSUInteger bytes, long long totalBytes, long long totalBytesExpected) = [operation.uploadProgress copy];
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        if (original) {
            original(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
        }

        if (totalBytesExpectedToWrite > 0) {
            [weakSelf setProgress:(totalBytesWritten / (totalBytesExpectedToWrite * 1.0f)) animated:animated];
        }
    }];
}

- (void)setProgressWithDownloadProgressOfOperation:(AFURLConnectionOperation *)operation
                                          animated:(BOOL)animated
{
    __weak __typeof(self)weakSelf = self;
    void (^original)(NSUInteger bytes, long long totalBytes, long long totalBytesExpected) = [operation.uploadProgress copy];
    [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        if (original) {
            original(bytesRead, totalBytesRead, totalBytesExpectedToRead);
        }
        
        if (totalBytesExpectedToRead > 0) {
            [weakSelf setProgress:(totalBytesRead / (totalBytesExpectedToRead  * 1.0f)) animated:animated];
        }
    }];
}

@end
