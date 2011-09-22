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

static UIImage * AFImageByScalingAndCroppingImageToSize(UIImage *image, CGSize size) {
    if (image == nil) {
        return nil;
    } else if (CGSizeEqualToSize(image.size, size) || CGSizeEqualToSize(size, CGSizeZero)) {
        return image;
    }
    
    CGSize scaledSize = size;
	CGPoint thumbnailPoint = CGPointZero;
    
    CGFloat widthFactor = size.width / image.size.width;
    CGFloat heightFactor = size.height / image.size.height;
    CGFloat scaleFactor = (widthFactor > heightFactor) ? widthFactor : heightFactor;
    scaledSize.width = image.size.width * scaleFactor;
    scaledSize.height = image.size.height * scaleFactor;
    if (widthFactor > heightFactor) {
        thumbnailPoint.y = (size.height - scaledSize.height) * 0.5; 
    } else if (widthFactor < heightFactor) {
        thumbnailPoint.x = (size.width - scaledSize.width) * 0.5;
    }
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0); 
    [image drawInRect:CGRectMake(thumbnailPoint.x, thumbnailPoint.y, scaledSize.width, scaledSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
	
	return newImage;
}

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
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLCacheStorageAllowed timeoutInterval:30.0];
    [request setHTTPShouldHandleCookies:NO];
    [request setHTTPShouldUsePipelining:YES];
    
    [self setImageWithURLRequest:request placeholderImage:placeholderImage success:nil failure:nil];
}

- (void)setImageWithURLRequest:(NSURLRequest *)urlRequest 
              placeholderImage:(UIImage *)placeholderImage 
                       success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response,UIImage *image))success
                       failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure
{
    if (![urlRequest URL] || (![self.imageRequestOperation isCancelled] && [[urlRequest URL] isEqual:self.imageRequestOperation.request.URL])) {
        return;
    } else {
        [self cancelImageRequestOperation];
    }
    
    NSString *cacheName = @"UIImageView";
    if (placeholderImage) {
        cacheName = [cacheName stringByAppendingFormat:@"(%@)", NSStringFromCGSize(placeholderImage.size)];
    }
    
    UIImage *cachedImage = [[AFImageCache sharedImageCache] cachedImageForURL:[urlRequest URL] cacheName:cacheName];
    if (cachedImage) {
        self.image = cachedImage;
        
        if (success) {
            success(nil, nil, cachedImage);
        }
    } else {
        self.image = placeholderImage;
        
        self.imageRequestOperation = [AFImageRequestOperation operationWithRequest:urlRequest imageProcessingBlock:^UIImage *(UIImage *image) {
            if (placeholderImage) {
                image = AFImageByScalingAndCroppingImageToSize(image, placeholderImage.size);
            }
            
            return image;
        } cacheName:cacheName success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            if (self.imageRequestOperation && ![self.imageRequestOperation isCancelled]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) {
                        success(request, response, image);
                    }
                
                    if ([[request URL] isEqual:[[self.imageRequestOperation request] URL]]) {
                        self.image = image;
                    } else {
                        self.image = placeholderImage;
                    }
                });
            }
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            self.imageRequestOperation = nil;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failure) {
                    failure(request, response, error);
                } 
            });
        }];
       
        [[[self class] sharedImageRequestOperationQueue] addOperation:self.imageRequestOperation];
    }
}

- (void)cancelImageRequestOperation {
    [self.imageRequestOperation cancel];
}

@end
