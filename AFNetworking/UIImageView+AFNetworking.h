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

#import <Foundation/Foundation.h>
#import "AFImageRequestOperation.h"

#import <Availability.h>

/** Options for controlling behavior asynchronous image retrieval of `UIImageView` category.
 */

typedef enum : NSInteger {
    kAFNetworkingImageViewOptionsCacheTypeNone = 0,
    kAFNetworkingImageViewOptionsCacheTypeRAM  = 1 << 0,
    kAFNetworkingImageViewOptionsCacheTypeDisk = 1 << 1,
    kAFNetworkingImageViewOptionsCacheTypeBoth = kAFNetworkingImageViewOptionsCacheTypeRAM | kAFNetworkingImageViewOptionsCacheTypeDisk
} AFNetworkImageViewOptions;

#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <UIKit/UIKit.h>

/**
 This category adds methods to the UIKit framework's `UIImageView` class. The methods in this category provide support for loading remote images asynchronously from a URL.
 */
@interface UIImageView (AFNetworking)

/************************************
 @name Asynchronous `image` retrieval
 ************************************/

/**
 Creates and enqueues an image request operation, which asynchronously downloads the image from the specified URL, and sets it the request is finished. Any previous image request for the receiver will be cancelled. If the image is cached locally, the image is set immediately, otherwise the specified placeholder image will be set immediately, and then the remote image will be set once the request is finished.

 By default, URL requests have a cache policy of `NSURLCacheStorageAllowed` and a timeout interval of 30 seconds, and are set not handle cookies. To configure URL requests differently, use `setImageWithURLRequest:placeholderImage:success:failure:`

 @param url The URL used for the image request.
 */
- (void)setImageWithURL:(NSURL *)url;

/**
 Creates and enqueues an image request operation, which asynchronously downloads the image from the specified URL. Any previous image request for the receiver will be cancelled. If the image is cached locally, the image is set immediately, otherwise the specified placeholder image will be set immediately, and then the remote image will be set once the request is finished.
 
 By default, URL requests have a cache policy of `NSURLCacheStorageAllowed` and a timeout interval of 30 seconds, and are set not handle cookies. To configure URL requests differently, use `setImageWithURLRequest:placeholderImage:success:failure:`. 
 
 By default, this will employ RAM-only caching (no disk caching). If you want to employ disk caching as well, use `setImageWithURL:placeholderImage:options:` with the `kAFNetworkingImageViewOptionsCacheTypeBoth` option.
 
 @param url The URL used for the image request.
 @param placeholderImage The image to be set initially, until the image request finishes. If `nil`, the image view will not change its image until the image request finishes.
 
 @see setImageWithURL:placeholderImage:options:
 */
- (void)setImageWithURL:(NSURL *)url
       placeholderImage:(UIImage *)placeholderImage;

/**
 Creates and enqueues an image request operation, which asynchronously downloads the image from the specified URL. Any previous image request for the receiver will be cancelled. If the image is cached locally, the image is set immediately, otherwise the specified placeholder image will be set immediately, and then the remote image will be set once the request is finished.
 
 By default, URL requests have a cache policy of `NSURLCacheStorageAllowed` and a timeout interval of 30 seconds, and are set not handle cookies. To configure URL requests differently, use `setImageWithURLRequest:placeholderImage:success:failure:`
 
 @param url The URL used for the image request.
 @param placeholderImage The image to be set initially, until the image request finishes. If `nil`, the image view will not change its image until the image request finishes.
 @param options The options availble include `kAFNetworkingImageViewOptionsCacheTypeRAM`, `kAFNetworkingImageViewOptionsCacheTypeDisk`, or `kAFNetworkingImageViewOptionsCacheTypeBoth`. If no caching to be performed, use `kAFNetworkingImageViewOptionsCacheTypeNone`.

 @see emptyDiskCache
 */
- (void)setImageWithURL:(NSURL *)url
       placeholderImage:(UIImage *)placeholderImage
                options:(AFNetworkImageViewOptions)options;

/**
 Creates and enqueues an image request operation, which asynchronously downloads the image with the specified URL request object. Any previous image request for the receiver will be cancelled. If the image is cached locally, the image is set immediately, otherwise the specified placeholder image will be set immediately, and then the remote image will be set once the request is finished.
 
 If a success block is specified, it is the responsibility of the block to set the image of the image view before returning. If no success block is specified, the default behavior of setting the image with `self.image = image` is executed.
 
 By default, this will employ RAM-based cache. If you want to use disk-based cache as well, use `setImageWithURLRequest:placeholderImage:options:success:failure` with the `option` value of `kAFNetworkingImageViewCacheTypeBoth`.
 
 @param urlRequest The URL request used for the image request.
 @param placeholderImage The image to be set initially, until the image request finishes. If `nil`, the image view will not change its image until the image request finishes.
 @param success A block to be executed when the image request operation finishes successfully, with a status code in the 2xx range, and with an acceptable content type (e.g. `image/png`). This block has no return value and takes three arguments: the request sent from the client, the response received from the server, and the image created from the response data of request. If the image was returned from cache, the request and response parameters will be `nil`.
 @param failure A block object to be executed when the image request operation finishes unsuccessfully, or that finishes successfully. This block has no return value and takes three arguments: the request sent from the client, the response received from the server, and the error object describing the network or parsing error that occurred.
 
 @see setImageWithURLRequest:placeholderImage:options:success:failure:
 */
- (void)setImageWithURLRequest:(NSURLRequest *)urlRequest
              placeholderImage:(UIImage *)placeholderImage
                       success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image))success
                       failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure;

/**
 Creates and enqueues an image request operation, which asynchronously downloads the image with the specified URL request object. Any previous image request for the receiver will be cancelled. If the image is cached locally, the image is set immediately, otherwise the specified placeholder image will be set immediately, and then the remote image will be set once the request is finished.
 
 If a success block is specified, it is the responsibility of the block to set the image of the image view before returning. If no success block is specified, the default behavior of setting the image with `self.image = image` is executed.
 
 @param urlRequest The URL request used for the image request.
 @param placeholderImage The image to be set initially, until the image request finishes. If `nil`, the image view will not change its image until the image request finishes.
 @param options The options for asynchronous image retrieval, specifically what caching is to be performed (if any). This is bitwise flag of `kAFNetworkingImageViewCacheTypeRAM`, `kAFNetworkingImageViewCacheTypeDisk`, or `kAFNetworkingImageViewCacheTypeBoth`. If no caching to be performed, use `kAFNetworkingImageViewCacheTypeNone`.
 @param success A block to be executed when the image request operation finishes successfully, with a status code in the 2xx range, and with an acceptable content type (e.g. `image/png`). This block has no return value and takes three arguments: the request sent from the client, the response received from the server, and the image created from the response data of request. If the image was returned from cache, the request and response parameters will be `nil`.
 @param failure A block object to be executed when the image request operation finishes unsuccessfully, or that finishes successfully. This block has no return value and takes three arguments: the request sent from the client, the response received from the server, and the error object describing the network or parsing error that occurred.
 
 @see emptyDiskCache
 */
- (void)setImageWithURLRequest:(NSURLRequest *)urlRequest
              placeholderImage:(UIImage *)placeholderImage
                       options:(AFNetworkImageViewOptions)options
                       success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image))success
                       failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure;

/*************************************
 @name Cancel image operation
 *************************************/

/**
 Cancels any executing image request operation for the receiver, if one exists.
 */
- (void)cancelImageRequestOperation;

/*************************************
 @name Disk cache management
 *************************************/

/**
 Retrieves `NSData` for image in disk cache.
 
 @param URL The `NSURL` for the image
 
 @return Returns the `NSData` of the resource on success; returns `nil` on failure.
 */
- (NSData *)diskCachedImageForURL:(NSURL *)URL;

/**
 Empty the disk image cache.
 
 @return Returns `YES` on success; returns `NO` on failure.
 
 @see setImageWithURL:placeholderImage:options:
 @see setImageWithURLRequest:placeholderImage:options:success:failure:

 */
- (BOOL)emptyDiskCache;

@end

#endif
