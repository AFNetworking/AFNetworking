// AFImageRequestOperation.m
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

#import "AFImageRequestOperation.h"
#import "AFImageCache.h"

#import "UIImage+AFNetworking.h"

static CGFloat const kAFImageRequestJPEGQuality = 0.8;
static NSUInteger const kAFImageRequestMaximumResponseSize = 8 * 1024 * 1024;

static inline CGSize kAFImageRequestRoundedCornerRadii(CGSize imageSize) {
    CGFloat dimension = fmaxf(imageSize.width, imageSize.height) * 0.1;
    return CGSizeMake(dimension, dimension);
}

@implementation AFImageRequestOperation

+ (id)operationWithRequest:(NSURLRequest *)urlRequest                
                   success:(void (^)(UIImage *image))success
{
    return [self operationWithRequest:urlRequest imageSize:CGSizeZero options:AFImageRequestDefaultOptions success:success];
}

+ (id)operationWithRequest:(NSURLRequest *)urlRequest
                 imageSize:(CGSize)imageSize
                   options:(AFImageRequestOptions)options
                   success:(void (^)(UIImage *image))success
{
    return [self operationWithRequest:urlRequest completion:^(NSURLRequest *request, NSHTTPURLResponse *response, NSData *data, NSError *error) {
        UIImage *image = nil;    
        if ([[UIScreen mainScreen] scale] == 2.0) {
            CGImageRef imageRef = [[UIImage imageWithData:data] CGImage];
            image = [UIImage imageWithCGImage:imageRef scale:2.0 orientation:UIImageOrientationUp];
        } else {
            image = [UIImage imageWithData:data]; 
        }
        
        if (!(CGSizeEqualToSize(image.size, imageSize) || CGSizeEqualToSize(imageSize, CGSizeZero))) {
            image = [UIImage imageByScalingAndCroppingImage:image size:imageSize];
        }
        if ((options & AFImageRequestRoundCorners)) {
            image = [UIImage imageByRoundingCornersOfImage:image corners:UIRectCornerAllCorners cornerRadii:kAFImageRequestRoundedCornerRadii(image.size)];
        }
        
        if (success) {
            success(image);
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            [[AFImageCache sharedImageCache] cacheImage:image forRequest:request imageSize:imageSize options:options];
        });
    }];
}

- (id)initWithRequest:(NSURLRequest *)urlRequest {
    self = [super initWithRequest:urlRequest];
    if (!self) {
        return nil;
    }
    
    self.runLoopModes = [NSSet setWithObject:NSRunLoopCommonModes];
    
    return self;
}

@end
