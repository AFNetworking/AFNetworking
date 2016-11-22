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

#import <TargetConditionals.h>

#if TARGET_OS_IOS || TARGET_OS_TV

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class AFImageDownloader;

/**
 This category adds methods to the UIKit framework's `UIButton` class. The methods in this category provide support for loading remote images and background images asynchronously from a URL.

 @warning Compound values for control `state` (such as `UIControlStateHighlighted | UIControlStateDisabled`) are unsupported.
 */
@interface UIButton (AFNetworking)

///------------------------------------
/// @name Accessing the Image Downloader
///------------------------------------

/**
 Set the shared image downloader used to download images.

 @param imageDownloader The shared image downloader used to download images.
*/
+ (void)setSharedImageDownloader:(AFImageDownloader *)imageDownloader;

/**
 The shared image downloader used to download images.
 */
+ (AFImageDownloader *)sharedImageDownloader;

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
        placeholderImage:(nullable UIImage *)placeholderImage;

/**
 Asynchronously downloads an image from the specified URL request, and sets it as the image for the specified state once the request is finished. Any previous image request for the receiver will be cancelled.

 If the image is cached locally, the image is set immediately, otherwise the specified placeholder image will be set immediately, and then the remote image will be set once the request is finished.

 If a success block is specified, it is the responsibility of the block to set the image of the button before returning. If no success block is specified, the default behavior of setting the image with `setImage:forState:` is applied.

 @param state The control state.
 @param urlRequest The URL request used for the image request.
 @param placeholderImage The image to be set initially, until the image request finishes. If `nil`, the button will not change its image until the image request finishes.
 @param success A block to be executed when the image data task finishes successfully. This block has no return value and takes three arguments: the request sent from the client, the response received from the server, and the image created from the response data of request. If the image was returned from cache, the response parameter will be `nil`.
 @param failure A block object to be executed when the image data task finishes unsuccessfully, or that finishes successfully. This block has no return value and takes three arguments: the request sent from the client, the response received from the server, and the error object describing the network or parsing error that occurred.
 */
- (void)setImageForState:(UIControlState)state
          withURLRequest:(NSURLRequest *)urlRequest
        placeholderImage:(nullable UIImage *)placeholderImage
                 success:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse * _Nullable response, UIImage *image))success
                 failure:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse * _Nullable response, NSError *error))failure;


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
                  placeholderImage:(nullable UIImage *)placeholderImage;

/**
 Asynchronously downloads an image from the specified URL request, and sets it as the image for the specified state once the request is finished. Any previous image request for the receiver will be cancelled.

 If the image is cached locally, the image is set immediately, otherwise the specified placeholder image will be set immediately, and then the remote image will be set once the request is finished.

 If a success block is specified, it is the responsibility of the block to set the image of the button before returning. If no success block is specified, the default behavior of setting the image with `setBackgroundImage:forState:` is applied.

 @param state The control state.
 @param urlRequest The URL request used for the image request.
 @param placeholderImage The background image to be set initially, until the background image request finishes. If `nil`, the button will not change its background image until the background image request finishes.
 @param success A block to be executed when the image data task finishes successfully. This block has no return value and takes three arguments: the request sent from the client, the response received from the server, and the image created from the response data of request. If the image was returned from cache, the response parameter will be `nil`.
 @param failure A block object to be executed when the image data task finishes unsuccessfully, or that finishes successfully. This block has no return value and takes three arguments: the request sent from the client, the response received from the server, and the error object describing the network or parsing error that occurred.
 */
- (void)setBackgroundImageForState:(UIControlState)state
                    withURLRequest:(NSURLRequest *)urlRequest
                  placeholderImage:(nullable UIImage *)placeholderImage
                           success:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse * _Nullable response, UIImage *image))success
                           failure:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse * _Nullable response, NSError *error))failure;


///------------------------------
/// @name Canceling Image Loading
///------------------------------

/**
 Cancels any executing image task for the specified control state of the receiver, if one exists.

 @param state The control state.
 */
- (void)cancelImageDownloadTaskForState:(UIControlState)state;

/**
 Cancels any executing background image task for the specified control state of the receiver, if one exists.

 @param state The control state.
 */
- (void)cancelBackgroundImageDownloadTaskForState:(UIControlState)state;

@end

NS_ASSUME_NONNULL_END

#endif
