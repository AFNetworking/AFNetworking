// UIActivityIndicatorView+AFNetworking.m
// Copyright (c) 2011–2016 Alamofire Software Foundation ( http://alamofire.org/ )
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
#import <objc/runtime.h>

#if TARGET_OS_IOS || TARGET_OS_TV

#import "AFURLSessionManager.h"

@interface AFActivityIndicatorViewNotificationObserver : NSObject
@property (readonly, nonatomic, weak) UIActivityIndicatorView *activityIndicatorView;//weak
- (instancetype)initWithActivityIndicatorView:(UIActivityIndicatorView *)activityIndicatorView;

- (void)setAnimatingWithStateOfTask:(NSURLSessionTask *)task;

@end

@implementation UIActivityIndicatorView (AFNetworking)//UIActivityIndicatorView 这个View的作用是什么**??**

- (AFActivityIndicatorViewNotificationObserver *)af_notificationObserver {
    AFActivityIndicatorViewNotificationObserver *notificationObserver = objc_getAssociatedObject(self, @selector(af_notificationObserver));
    if (notificationObserver == nil) {
        notificationObserver = [[AFActivityIndicatorViewNotificationObserver alloc] initWithActivityIndicatorView:self];
        objc_setAssociatedObject(self, @selector(af_notificationObserver), notificationObserver, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
//        objc_setAssociatedObject(<#id object#>, <#const void *key#>, <#id value#>, <#objc_AssociationPolicy policy#>)
    }
    return notificationObserver;
}

- (void)setAnimatingWithStateOfTask:(NSURLSessionTask *)task {
    [[self af_notificationObserver] setAnimatingWithStateOfTask:task];
}

@end

@implementation AFActivityIndicatorViewNotificationObserver

- (instancetype)initWithActivityIndicatorView:(UIActivityIndicatorView *)activityIndicatorView
{
    self = [super init];
    if (self) {
        _activityIndicatorView = activityIndicatorView;//weak,仅仅是将View传过来
    }
    return self;
}

- (void)setAnimatingWithStateOfTask:(NSURLSessionTask *)task {
    /*
     NSURLSessionTask:代表一个请求任务。eg，
     （1）获得NSURLSession对象
     
     NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
      (2)创建请求任务
     
     NSURLSessionTask *task = [session dataTaskWithRequest:（此处为NSURLRequest对象）];
      (3)启动任务
     
     [task resume];
     */
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    //先移除之前的Observer, 防止多次添加（多次移除同一标识的消息观察者不会引起崩溃）
    [notificationCenter removeObserver:self name:AFNetworkingTaskDidResumeNotification object:nil];
    [notificationCenter removeObserver:self name:AFNetworkingTaskDidSuspendNotification object:nil];
    [notificationCenter removeObserver:self name:AFNetworkingTaskDidCompleteNotification object:nil];
    
    if (task) {
        if (task.state != NSURLSessionTaskStateCompleted) {
            UIActivityIndicatorView *activityIndicatorView = self.activityIndicatorView;
            if (task.state == NSURLSessionTaskStateRunning) {
                [activityIndicatorView startAnimating];
            } else {
                [activityIndicatorView stopAnimating];
            }
            /*
             AFNetworkingTaskDidResumeNotification:任务继续
             AFNetworkingTaskDidCompleteNotification:任务完成
             AFNetworkingTaskDidSuspendNotification:任务挂起
             */
            //添加观察者
            [notificationCenter addObserver:self selector:@selector(af_startAnimating) name:AFNetworkingTaskDidResumeNotification object:task];
            [notificationCenter addObserver:self selector:@selector(af_stopAnimating) name:AFNetworkingTaskDidCompleteNotification object:task];
            [notificationCenter addObserver:self selector:@selector(af_stopAnimating) name:AFNetworkingTaskDidSuspendNotification object:task];
        }
    }
}

#pragma mark -

- (void)af_startAnimating {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.activityIndicatorView startAnimating];
    });
}

- (void)af_stopAnimating {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.activityIndicatorView stopAnimating];
    });
}

#pragma mark -

- (void)dealloc {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter removeObserver:self name:AFNetworkingTaskDidCompleteNotification object:nil];
    [notificationCenter removeObserver:self name:AFNetworkingTaskDidResumeNotification object:nil];
    [notificationCenter removeObserver:self name:AFNetworkingTaskDidSuspendNotification object:nil];
}

@end

#endif
