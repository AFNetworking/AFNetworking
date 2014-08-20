// AFImageCache.h
//
// Copyright (c) 2013-2014 AFNetworking (http://afnetworking.com)
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

/**
 The `AFImageCache` protocol is adopted by an object used to cache images loaded by the AFNetworking category on `UIImageView`.
 */
@protocol AFImageCache <NSObject>

/**
 Returns a cached image for the specififed request, if available.
 
 @param request The image request.
 
 @return The cached image.
 */
- (UIImage *)cachedImageForRequest:(NSURLRequest *)request;

/**
 Caches a particular image for the specified request.
 
 @param image The image to cache.
 @param request The request to be used as a cache key.
 */
- (void)cacheImage:(UIImage *)image
        forRequest:(NSURLRequest *)request;
@end

@interface AFImageCache : NSCache <AFImageCache>

///----------------------------
/// @name Accessing Image Cache
///----------------------------

/**
 The image cache used to improve image loadiing performance on scroll views. By default, this is an `NSCache` subclass conforming to the `AFImageCache` protocol, which listens for notification warnings and evicts objects accordingly.
 */
+ (id <AFImageCache>)sharedImageCache;

/**
 Set the cache used for image loading.
 
 @param imageCache The image cache.
 */
+ (void)setSharedImageCache:(id <AFImageCache>)imageCache;

@end
