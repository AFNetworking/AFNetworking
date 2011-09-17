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
#import "UIImage+AFNetworking.h"

#import "AFImageCache.h"

static NSString * const kUIImageViewImageRequestObjectKey = @"_af_imageRequestOperation";

@interface UIImageView (_AFNetworking)
@property (readwrite, nonatomic, retain) AFImageRequestOperation *imageRequestOperation;
@end

@implementation UIImageView (_AFNetworking)
@dynamic imageRequestOperation;
@end

#pragma mark -

@implementation UIImageView (AFNetworking)

- (AFHTTPRequestOperation *)imageRequestOperation {
    return (AFHTTPRequestOperation *)objc_getAssociatedObject(self, kUIImageViewImageRequestObjectKey);
}

- (void)setImageRequestOperation:(AFImageRequestOperation *)imageRequestOperation {
    objc_setAssociatedObject(self, kUIImageViewImageRequestObjectKey, imageRequestOperation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (NSOperationQueue *)sharedImageRequestOperationQueue {
    static NSOperationQueue *_imageRequestOperationQueue = nil;
    
    if (!_imageRequestOperationQueue) {
        _imageRequestOperationQueue = [[NSOperationQueue alloc] init];
        [_imageRequestOperationQueue setMaxConcurrentOperationCount:8];
    }
    
    return _imageRequestOperationQueue;
}

#pragma mark -

- (void)setImageWithURL:(NSURL *)url {
    [self setImageWithURL:url placeholderImage:nil];
}

- (void)setImageWithURL:(NSURL *)url 
       placeholderImage:(UIImage *)placeholderImage
{
    [self setImageWithURL:url placeholderImage:placeholderImage success:nil]; 
}

- (void)setImageWithURL:(NSURL *)url 
       placeholderImage:(UIImage *)placeholderImage 
                success:(void (^)(UIImage *image, BOOL cacheUsed))success
{
    if (!url || [url isEqual:self.imageRequestOperation.request.URL]) {
        return;
    } else {
        [self cancelImageRequestOperation];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLCacheStorageAllowed timeoutInterval:30.0];
    [request setHTTPShouldHandleCookies:NO];
    [request setHTTPShouldUsePipelining:YES];
    
    NSString *cacheName = @"UIImageView";
    if (placeholderImage) {
        cacheName = [cacheName stringByAppendingFormat:@"(%@)", NSStringFromCGSize(placeholderImage.size)];
    }
    
    UIImage *cachedImage = [[AFImageCache sharedImageCache] cachedImageForRequest:request cacheName:cacheName];
    if (cachedImage) {
        self.image = cachedImage;
        
        if (success) {
            success(cachedImage, YES);
        }
    } else {
        self.image = placeholderImage;
        
        self.imageRequestOperation = [AFImageRequestOperation operationWithRequest:request imageProcessingBlock:^UIImage *(UIImage *image) {
            if (placeholderImage) {
                image = [UIImage imageByScalingAndCroppingImage:image size:placeholderImage.size];
            }
            
            return image;
        } cacheName:cacheName success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            if (self.imageRequestOperation && ![self.imageRequestOperation isCancelled]) {
                if (success) {
                    success(image, NO);
                }
                
                if ([[request URL] isEqual:[[self.imageRequestOperation request] URL]]) {
                    self.image = image;
                } else {
                    self.image = placeholderImage;
                }                
            }
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            self.imageRequestOperation = nil;
        }];
       
        [[[self class] sharedImageRequestOperationQueue] addOperation:self.imageRequestOperation];
    }
}

- (void)cancelImageRequestOperation {
    [self.imageRequestOperation cancel];
}

@end
