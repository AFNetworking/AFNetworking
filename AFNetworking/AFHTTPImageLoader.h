// AFHTTPRequestOperation.h
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

#import <Foundation/Foundation.h>

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)

#import <UIKit/UIKit.h>

@protocol AFImageCache, AFURLResponseSerialization;
@class AFImageResponseSerializer;

typedef void(^AFHTTPImageLoaderSuccessBlock)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image);
typedef void(^AFHTTPImageLoaderFailureBlock)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error);

@interface AFHTTPImageLoader : NSObject

///----------------------------
/// @name Accessing Image Cache
///----------------------------

/**
 The image cache used to improve image loadiing performance on scroll views. By default, this is an `NSCache` subclass conforming to the `AFImageCache` protocol, which listens for notification warnings and evicts objects accordingly.
 */
@property (nonatomic, strong) id<AFImageCache> imageCache;

///------------------------------------
/// @name Accessing Response Serializer
///------------------------------------

/**
 The response serializer used to create an image representation from the server response and response data. By default, this is an instance of `AFImageResponseSerializer`.
 
 @discussion Subclasses of `AFImageResponseSerializer` could be used to perform post-processing, such as color correction, face detection, or other effects. See https://github.com/AFNetworking/AFCoreImageSerializer
 */
@property (nonatomic, strong) AFImageResponseSerializer <AFURLResponseSerialization> * imageResponseSerializer;

#pragma mark - Shared Image Cache

/**
 Use this method to get the shared image cache for this class.  This is the default image cache used when imageCache is not explicitely set.
 
 @returns	The shared image cache.  Will never be nil.
 */
+ (id <AFImageCache>)sharedImageCache;

#pragma mark - Requesting images

/**
 Use this method to asynchronously request an image with an URL.
 
 @param url					The url for the image. Cannot be nil.
 @param	success				The block to execute on success.  Can be nil.
 @param	failure				The block to execute on failure.  Can be nil.
 
 @returns	If a cached image is found, it is returned immediately and the success and failure blocks will never
			be executed.
 */
- (UIImage*)imageWithURL:(NSURL *)url
				 success:(AFHTTPImageLoaderSuccessBlock)success
				 failure:(AFHTTPImageLoaderFailureBlock)failure;

/**
 Use this method to asynchronously request an image with an URL request.
 
 @param urlRequest			The request for the image. Cannot be nil.
 @param	success				The block to execute on success.  Can be nil.
 @param	failure				The block to execute on failure.  Can be nil.
 
 @returns	If a cached image is found, it is returned immediately and the success and failure blocks will never
			be executed.
 */
- (UIImage*)imageWithURLRequest:(NSURLRequest *)urlRequest
						success:(AFHTTPImageLoaderSuccessBlock)success
						failure:(AFHTTPImageLoaderFailureBlock)failure;

/**
 Cancels any executing image operation for the receiver, if one exists.
 */
- (void)cancelImageRequestOperation;

@end

#pragma mark -

/**
 The `AFImageCache` protocol is adopted by an object used to cache images loaded by the AFNetworking category on `UIImageView`.
 */
@protocol AFImageCache

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

#endif
