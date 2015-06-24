// UIButton+AFNetworking.h
// Copyright (c) 2011–2015 Alamofire Software Foundation (http://alamofire.org/)
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

#import <Availability.h>

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)

#import <UIKit/UIKit.h>

@protocol AFURLResponseSerialization, AFImageCache;

/**
 This category adds methods to the UIKit framework's `UIButton` class. The methods in this category provide support for loading remote images and background images asynchronously from a URL.

 @warning Compound values for control `state` (such as `UIControlStateHighlighted | UIControlStateDisabled`) are unsupported.
 */
@interface UIButton (AFNetworking)

///----------------------------
/// @name Accessing Image Cache
///----------------------------

/**
 The image cache used to improve image loadiing performance on scroll views. By default, `UIButton` will use the `sharedImageCache` of `UIImageView`.
 */
+ (id <AFImageCache>)sharedImageCache;

/**
 Set the cache used for image loading.

 @param imageCache The image cache.
 */
+ (void)setSharedImageCache:(id <AFImageCache>)imageCache;

///------------------------------------
/// @name Accessing Response Serializer
///------------------------------------

/**
 The response serializer used to create an image representation from the server response and response data. By default, this is an instance of `AFImageResponseSerializer`.

 @discussion Subclasses of `AFImageResponseSerializer` could be used to perform post-processing, such as color correction, face detection, or other effects. See https://github.com/AFNetworking/AFCoreImageSerializer
 */
@property (nonatomic, strong) id <AFURLResponseSerialization> imageResponseSerializer;

///--------------------
/// @name Setting Image
///--------------------

/**
 Asynchronously downloads an image from the specified URL, and sets it as the image for the specified state once the request is finished. Any previous image request for the receiver will be cancelled.

  If the image is cached locally, the image is set immediately, otherwise the specified placeholder image will be set immediately, and then the remote image will be set once the request is finished.

 @param state The control state.
 @param url The URL used for the image request.
 */
- (void)setImageForState:(UIControlState)state
                 withURL:(NSURL *)url;

/**
 Asynchronously downloads an image from the specified URL, and sets it as the image for the specified state once the request is finished. Any previous image request for the receiver will be cancelled.

 If the image is cached locally, the image is set immediately, otherwise the specified placeholder image will be set immediately, and then the remote image will be set once the request is finished.

 @param state The control state.
 @param url The URL used for the image request.
 @param placeholderImage The image to be set initially, until the image request finishes. If `nil`, the button will not change its image until the image request finishes.
 */
- (void)setImageForState:(UIControlState)state
                 withURL:(NSURL *)url
        placeholderImage:(UIImage *)placeholderImage;

/**
 Asynchronously downloads an image from the specified URL request, and sets it as the image for the specified state once the request is finished. Any previous image request for the receiver will be cancelled.

 If the image is cached locally, the image is set immediately, otherwise the specified placeholder image will be set immediately, and then the remote image will be set once the request is finished.

 If a success block is specified, it is the responsibility of the block to set the image of the button before returning. If no success block is specified, the default behavior of setting the image with `setImage:forState:` is applied.

 @param state The control state.
 @param urlRequest The URL request used for the image request.
 @param placeholderImage The image to be set initially, until the image request finishes. If `nil`, the button will not change its image until the image request finishes.
 @param success A block to be executed when the image request operation finishes successfully. This block has no return value and takes two arguments: the server response and the image. If the image was returned from cache, the request and response parameters will be `nil`.
 @param failure A block object to be executed when the image request operation finishes unsuccessfully, or that finishes successfully. This block has no return value and takes a single argument: the error that occurred.
 */
- (void)setImageForState:(UIControlState)state
          withURLRequest:(NSURLRequest *)urlRequest
        placeholderImage:(UIImage *)placeholderImage
                 success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image))success
                 failure:(void (^)(NSError *error))failure;


///-------------------------------
/// @name Setting Background Image
///-------------------------------

/**
 Asynchronously downloads an image from the specified URL, and sets it as the background image for the specified state once the request is finished. Any previous background image request for the receiver will be cancelled.

 If the background image is cached locally, the background image is set immediately, otherwise the specified placeholder background image will be set immediately, and then the remote background image will be set once the request is finished.

 @param state The control state.
 @param url The URL used for the background image request.
 */
- (void)setBackgroundImageForState:(UIControlState)state
                           withURL:(NSURL *)url;

/**
 Asynchronously downloads an image from the specified URL, and sets it as the background image for the specified state once the request is finished. Any previous image request for the receiver will be cancelled.

 If the image is cached locally, the image is set immediately, otherwise the specified placeholder image will be set immediately, and then the remote image will be set once the request is finished.

 @param state The control state.
 @param url The URL used for the background image request.
 @param placeholderImage The background image to be set initially, until the background image request finishes. If `nil`, the button will not change its background image until the background image request finishes.
 */
- (void)setBackgroundImageForState:(UIControlState)state
                           withURL:(NSURL *)url
                  placeholderImage:(UIImage *)placeholderImage;

/**
 Asynchronously downloads an image from the specified URL request, and sets it as the image for the specified state once the request is finished. Any previous image request for the receiver will be cancelled.

 If the image is cached locally, the image is set immediately, otherwise the specified placeholder image will be set immediately, and then the remote image will be set once the request is finished.

 If a success block is specified, it is the responsibility of the block to set the image of the button before returning. If no success block is specified, the default behavior of setting the image with `setBackgroundImage:forState:` is applied.

 @param state The control state.
 @param urlRequest The URL request used for the image request.
 @param placeholderImage The background image to be set initially, until the background image request finishes. If `nil`, the button will not change its background image until the background image request finishes.
 */
- (void)setBackgroundImageForState:(UIControlState)state
                    withURLRequest:(NSURLRequest *)urlRequest
                  placeholderImage:(UIImage *)placeholderImage
                           success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image))success
                           failure:(void (^)(NSError *error))failure;


///------------------------------
/// @name Canceling Image Loading
///------------------------------

/**
 Cancels any executing image operation for the specified control state of the receiver, if one exists.

 @param state The control state.
 */
- (void)cancelImageRequestOperationForState:(UIControlState)state;

/**
 Cancels any executing background image operation for the specified control state of the receiver, if one exists.

 @param state The control state.
 */
- (void)cancelBackgroundImageRequestOperationForState:(UIControlState)state;

@end

#endif
