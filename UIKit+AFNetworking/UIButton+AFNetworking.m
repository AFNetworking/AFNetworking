// UIButton+AFNetworking.m
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

#import "UIButton+AFNetworking.h"

#import <objc/runtime.h>

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)

#import "AFHTTPRequestOperation.h"

@interface UIButton (_AFNetworking)
@property (readwrite, nonatomic, strong, setter = af_setImageRequestOperation:) AFHTTPRequestOperation *af_imageRequestOperation;
@property (readwrite, nonatomic, strong, setter = af_setBackgroundImageRequestOperation:) AFHTTPRequestOperation *af_backgroundImageRequestOperation;
@end

@implementation UIButton (_AFNetworking)

+ (NSOperationQueue *)af_sharedImageRequestOperationQueue {
    static NSOperationQueue *_af_sharedImageRequestOperationQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _af_sharedImageRequestOperationQueue = [[NSOperationQueue alloc] init];
        _af_sharedImageRequestOperationQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
    });

    return _af_sharedImageRequestOperationQueue;
}

- (AFHTTPRequestOperation *)af_imageRequestOperation {
    return (AFHTTPRequestOperation *)objc_getAssociatedObject(self, @selector(af_imageRequestOperation));
}

- (void)af_setImageRequestOperation:(AFHTTPRequestOperation *)imageRequestOperation {
    objc_setAssociatedObject(self, @selector(af_imageRequestOperation), imageRequestOperation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (AFHTTPRequestOperation *)af_backgroundImageRequestOperation {
    return (AFHTTPRequestOperation *)objc_getAssociatedObject(self, @selector(af_backgroundImageRequestOperation));
}

- (void)af_setBackgroundImageRequestOperation:(AFHTTPRequestOperation *)imageRequestOperation {
    objc_setAssociatedObject(self, @selector(af_backgroundImageRequestOperation), imageRequestOperation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

#pragma mark -

@implementation UIButton (AFNetworking)

- (void)setImageForState:(UIControlState)state
                 withURL:(NSURL *)url
{
    [self setImageForState:state withURL:url placeholderImage:nil];
}

- (void)setImageForState:(UIControlState)state
                 withURL:(NSURL *)url
        placeholderImage:(UIImage *)placeholderImage
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];

    [self setImageForState:state withURLRequest:request placeholderImage:placeholderImage success:nil failure:nil];
}

- (void)setImageForState:(UIControlState)state
          withURLRequest:(NSURLRequest *)urlRequest
        placeholderImage:(UIImage *)placeholderImage
                 success:(void (^)(NSHTTPURLResponse *response, UIImage *image))success
                 failure:(void (^)(NSError *error))failure
{
    [self cancelImageRequestOperation];

    [self setImage:placeholderImage forState:state];

    __weak __typeof(self)weakSelf = self;
    self.af_imageRequestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
    self.af_imageRequestOperation.responseSerializer = [AFImageResponseSerializer serializer];
    [self.af_imageRequestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        if ([[urlRequest URL] isEqual:[operation.request URL]]) {
            if (success) {
                success(operation.response, responseObject);
            } else if (responseObject) {
                [strongSelf setImage:responseObject forState:state];
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if ([[urlRequest URL] isEqual:[operation.response URL]]) {
            if (failure) {
                failure(error);
            }
        }
    }];

    [[[self class] af_sharedImageRequestOperationQueue] addOperation:self.af_imageRequestOperation];
}

#pragma mark -

- (void)setBackgroundImageForState:(UIControlState)state
                           withURL:(NSURL *)url
{
    [self setBackgroundImageForState:state withURL:url placeholderImage:nil];
}

- (void)setBackgroundImageForState:(UIControlState)state
                           withURL:(NSURL *)url
                  placeholderImage:(UIImage *)placeholderImage
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];

    [self setBackgroundImageForState:state withURLRequest:request placeholderImage:placeholderImage success:nil failure:nil];
}

- (void)setBackgroundImageForState:(UIControlState)state
                    withURLRequest:(NSURLRequest *)urlRequest
                  placeholderImage:(UIImage *)placeholderImage
                           success:(void (^)(NSHTTPURLResponse *response, UIImage *image))success
                           failure:(void (^)(NSError *error))failure
{
    [self cancelBackgroundImageRequestOperation];

    [self setBackgroundImage:placeholderImage forState:state];

    __weak __typeof(self)weakSelf = self;
    self.af_backgroundImageRequestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
    self.af_backgroundImageRequestOperation.responseSerializer = [AFImageResponseSerializer serializer];
    [self.af_backgroundImageRequestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        if ([[urlRequest URL] isEqual:[operation.request URL]]) {
            if (success) {
                success(operation.response, responseObject);
            } else if (responseObject) {
                [strongSelf setBackgroundImage:responseObject forState:state];
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if ([[urlRequest URL] isEqual:[operation.response URL]]) {
            if (failure) {
                failure(error);
            }
        }
    }];

    [[[self class] af_sharedImageRequestOperationQueue] addOperation:self.af_backgroundImageRequestOperation];
}

#pragma mark -

- (void)cancelImageRequestOperation {
    [self.af_imageRequestOperation cancel];
    self.af_imageRequestOperation = nil;
}

- (void)cancelBackgroundImageRequestOperation {
    [self.af_backgroundImageRequestOperation cancel];
    self.af_backgroundImageRequestOperation = nil;
}

@end

#endif
