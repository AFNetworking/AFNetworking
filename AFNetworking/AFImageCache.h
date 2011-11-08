// AFImageCache.h
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
#import "AFImageRequestOperation.h"

#import <Availability.h>

/**
 `AFImageCache` is an `NSCache` that stores and retrieves images from cache.
 
 @discussion `AFImageCache` is used to cache images for successful `AFImageRequestOperations` with the proper cache policy.
 */
@interface AFImageCache : NSCache

/**
 Returns the shared image cache object for the system.
 
 @return The systemwide image cache.
 */
+ (AFImageCache *)sharedImageCache;

/**
 Returns the image associated with a given URL and cache name.
 
 @param url The URL associated with the image in the cache.
 @param cacheName The cache name associated with the image in the cache. This allows for multiple versions of an image to be associated for a single URL, such as image thumbnails, for instance.
 
 @return The image associated with the URL and cache name, or `nil` if not image exists.
 */

#if __IPHONE_OS_VERSION_MIN_REQUIRED
- (UIImage *)cachedImageForURL:(NSURL *)url
                     cacheName:(NSString *)cacheName;
#elif __MAC_OS_X_VERSION_MIN_REQUIRED
- (NSImage *)cachedImageForURL:(NSURL *)url
                     cacheName:(NSString *)cacheName;
#endif

/**
 Stores image data into cache, associated with a given URL and cache name.
 
 @param imageData The image data to be stored in cache.
 @param url The URL to be associated with the image.
 @param cacheName The cache name to be associated with the image in the cache. This allows for multiple versions of an image to be associated for a single URL, such as image thumbnails, for instance.
 */
- (void)cacheImageData:(NSData *)imageData
                forURL:(NSURL *)url
             cacheName:(NSString *)cacheName;

@end
