// UIImageView+AFNetworking.m
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

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#import "UIImageView+AFNetworking.h"

#import "AFImageCache.h"

static NSString * const kUIImageViewImageRequestObjectKey = @"_af_imageRequestOperation";

@interface UIImageView (_AFNetworking)
@property (readwrite, nonatomic, retain) AFImageRequestOperation *afImageRequestOperation;
@end

@implementation UIImageView (_AFNetworking)
@dynamic afImageRequestOperation;
@end

#pragma mark -

@implementation UIImageView (AFNetworking)

#ifndef AFNETWORKING_NO_DEPRECATED
- (void)setImageWithURL:(NSURL *)url {
#ifndef NDEBUG
    NSLog(@"Use of deprecated category method: %s", __PRETTY_FUNCTION__);
#endif
    [self afSetImageWithURL:url];
}

- (void)setImageWithURL:(NSURL *)url 
       placeholderImage:(UIImage *)placeholderImage {
#ifndef NDEBUG
    NSLog(@"Use of deprecated category method: %s", __PRETTY_FUNCTION__);
#endif
    [self afSetImageWithURL:url placeholderImage:placeholderImage];
}

- (void)setImageWithURL:(NSURL *)url 
       placeholderImage:(UIImage *)placeholderImage 
              imageSize:(CGSize)imageSize 
                options:(AFImageRequestOptions)options {
#ifndef NDEBUG
    NSLog(@"Use of deprecated category method: %s", __PRETTY_FUNCTION__);
#endif
    [self afSetImageWithURL:url placeholderImage:placeholderImage imageSize:imageSize options:options];
}

- (void)setImageWithURL:(NSURL *)url 
       placeholderImage:(UIImage *)placeholderImage 
              imageSize:(CGSize)imageSize 
                options:(AFImageRequestOptions)options
                  block:(void (^)(UIImage *image, BOOL cacheUsed))block {
#ifndef NDEBUG
    NSLog(@"Use of deprecated category method: %s", __PRETTY_FUNCTION__);
#endif
    [self afSetImageWithURL:url placeholderImage:placeholderImage imageSize:imageSize options:options block:block];
}

- (void)cancelImageRequestOperation {
#ifndef NDEBUG
    NSLog(@"Use of deprecated category method: %s", __PRETTY_FUNCTION__);
#endif
    [self afCancelImageRequestOperation];
}
#endif

- (AFHTTPRequestOperation *)afImageRequestOperation {
    return (AFHTTPRequestOperation *)objc_getAssociatedObject(self, kUIImageViewImageRequestObjectKey);
}

- (void)setAfImageRequestOperation:(AFImageRequestOperation *)imageRequestOperation {
    objc_setAssociatedObject(self, kUIImageViewImageRequestObjectKey, imageRequestOperation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (NSOperationQueue *)afSharedImageRequestOperationQueue {
    static NSOperationQueue *_imageRequestOperationQueue = nil;
    
    if (!_imageRequestOperationQueue) {
        _imageRequestOperationQueue = [[NSOperationQueue alloc] init];
        [_imageRequestOperationQueue setMaxConcurrentOperationCount:6];
    }
    
    return _imageRequestOperationQueue;
}

#pragma mark -
 
- (void)afSetImageWithURL:(NSURL *)url {
    [self afSetImageWithURL:url placeholderImage:nil];
}

- (void)afSetImageWithURL:(NSURL *)url 
       placeholderImage:(UIImage *)placeholderImage 
{
    [self afSetImageWithURL:url placeholderImage:placeholderImage imageSize:self.frame.size options:AFImageRequestDefaultOptions];
}

- (void)afSetImageWithURL:(NSURL *)url 
         placeholderImage:(UIImage *)placeholderImage 
                imageSize:(CGSize)imageSize 
                  options:(AFImageRequestOptions)options 
{
    [self afSetImageWithURL:url placeholderImage:placeholderImage imageSize:imageSize options:options block:nil];
}

- (void)afSetImageWithURL:(NSURL *)url 
         placeholderImage:(UIImage *)placeholderImage 
                imageSize:(CGSize)imageSize 
                  options:(AFImageRequestOptions)options
                    block:(void (^)(UIImage *image, BOOL cacheUsed))block
{
    if (!url || [url isEqual:self.afImageRequestOperation.request.URL]) {
        return;
    } else {
        [self afCancelImageRequestOperation];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLCacheStorageAllowed timeoutInterval:30.0];
    [request setHTTPShouldHandleCookies:NO];
    [request setHTTPShouldUsePipelining:YES];
    
    UIImage *cachedImage = [[AFImageCache sharedImageCache] cachedImageForRequest:request imageSize:imageSize options:options];
    if (cachedImage) {
        self.image = cachedImage;
        
        if (block) {
            block(cachedImage, YES);
        }
    } else {
        self.image = placeholderImage;
        
        self.afImageRequestOperation = [AFImageRequestOperation operationWithRequest:request imageSize:imageSize options:options success:^(UIImage *image) {
            if (self.afImageRequestOperation && ![self.afImageRequestOperation isCancelled]) {
                if (block) {
                    block(image, NO);
                }

                if ([[request URL] isEqual:[[self.afImageRequestOperation request] URL]]) {
                    self.image = image;
                } else {
                    self.image = placeholderImage;
                }                
            }
        }];
        
        [[[self class] afSharedImageRequestOperationQueue] addOperation:self.afImageRequestOperation];
    }
}

- (void)afCancelImageRequestOperation {
    [self.afImageRequestOperation cancel];
}

@end
