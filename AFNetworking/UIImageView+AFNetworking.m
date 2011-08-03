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

#import "UIImageView+AFNetworking.h"

#import "AFImageCache.h"

static NSString * const kUIImageViewImageRequestObjectKey = @"imageRequestOperation";

@interface UIImageView (_AFNetworking)
@property (readwrite, nonatomic, retain) AFImageRequestOperation *imageRequestOperation;
@end

@implementation UIImageView (_AFNetworking)
@dynamic imageRequestOperation;
@end

#pragma mark -

@implementation UIImageView (AFNetworking)

- (AFHTTPRequestOperation *)imageRequestOperation {
    return objc_getAssociatedObject(self, kUIImageViewImageRequestObjectKey);
}

- (void)setImageRequestOperation:(AFImageRequestOperation *)imageRequestOperation {
    objc_setAssociatedObject(self, kUIImageViewImageRequestObjectKey, imageRequestOperation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (NSOperationQueue *)sharedImageRequestOperationQueue {
    static NSOperationQueue *_imageRequestOperationQueue = nil;
    
    if (!_imageRequestOperationQueue) {
        _imageRequestOperationQueue = [[NSOperationQueue alloc] init];
        [_imageRequestOperationQueue setMaxConcurrentOperationCount:6];
    }
    
    return _imageRequestOperationQueue;
}
 
- (void)setImageWithURL:(NSURL *)url {
    [self setImageWithURL:url placeholderImage:nil];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholderImage {
    [self setImageWithURL:url placeholderImage:placeholderImage imageSize:self.frame.size options:AFImageRequestDefaultOptions];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholderImage imageSize:(CGSize)imageSize options:(AFImageRequestOptions)options {
    if (!url) {
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLCacheStorageAllowed timeoutInterval:30.0];
    [request setHTTPShouldHandleCookies:NO];
    [request setHTTPShouldUsePipelining:YES];
        
    UIImage *cachedImage = [[AFImageCache sharedImageCache] cachedImageForRequest:request imageSize:imageSize options:options];
    if (cachedImage) {
        self.image = cachedImage;
    } else {
        self.image = placeholderImage;
        
        self.imageRequestOperation = [AFImageRequestOperation operationWithRequest:request imageSize:imageSize options:options success:^(UIImage *image) {
            if ([[request URL] isEqual:[[self.imageRequestOperation request] URL]]) {
                self.image = image;
            } else {
                self.image = placeholderImage;
            }
        }];
        
        [[[self class] sharedImageRequestOperationQueue] addOperation:self.imageRequestOperation];
    }
}

@end
