// UIImageView+AFNetworking.h
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

#import <UIKit/UIKit.h>
#import "AFImageRequestOperation.h"

@interface UIImageView (AFNetworking)

#ifndef AFNETWORKING_NO_DEPRECATED
- (void)setImageWithURL:(NSURL *)url __attribute__((deprecated("Will be removed in a future release. Please use afSetImageWithURL:.")));

- (void)setImageWithURL:(NSURL *)url 
       placeholderImage:(UIImage *)placeholderImage __attribute__((deprecated("Will be removed in a future release. Please use afSetImageWithURL:placeholderImage:.")));

- (void)setImageWithURL:(NSURL *)url 
       placeholderImage:(UIImage *)placeholderImage 
              imageSize:(CGSize)imageSize 
                options:(AFImageRequestOptions)options __attribute__((deprecated("Will be removed in a future release. Please use afSetImageWithURL:.")));

- (void)setImageWithURL:(NSURL *)url 
       placeholderImage:(UIImage *)placeholderImage 
              imageSize:(CGSize)imageSize 
                options:(AFImageRequestOptions)options
                  block:(void (^)(UIImage *image, BOOL cacheUsed))block __attribute__((deprecated("Will be removed in a future release. Please use afSetImageWithURL:placeholderImage:imageSize:options:block:.")));

- (void)cancelImageRequestOperation __attribute__((deprecated("Will be removed in a future release. Please use afCancelImageRequestOperation.")));
#endif

- (void)afSetImageWithURL:(NSURL *)url;

- (void)afSetImageWithURL:(NSURL *)url 
         placeholderImage:(UIImage *)placeholderImage;

- (void)afSetImageWithURL:(NSURL *)url 
         placeholderImage:(UIImage *)placeholderImage 
                imageSize:(CGSize)imageSize 
                  options:(AFImageRequestOptions)options;

- (void)afSetImageWithURL:(NSURL *)url 
         placeholderImage:(UIImage *)placeholderImage 
                imageSize:(CGSize)imageSize 
                  options:(AFImageRequestOptions)options
                    block:(void (^)(UIImage *image, BOOL cacheUsed))block;

- (void)afCancelImageRequestOperation;

@end
