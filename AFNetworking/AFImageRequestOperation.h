// AFImageRequestOperation.h
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
#import "AFHTTPRequestOperation.h"

#import <Availability.h>

#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <UIKit/UIKit.h>
#elif __MAC_OS_X_VERSION_MIN_REQUIRED 
#import <Cocoa/Cocoa.h>
#endif

/**
 `AFImageRequestOperation` is a subclass of `AFHTTPRequestOperation` for downloading an processing images.
 
 ## Acceptable Content Types
 
 By default, `AFImageRequestOperation` accepts the following MIME types, which correspond to the image formats supported by UIImage or NSImage:
 
 - `image/tiff`
 - `image/jpeg`
 - `image/gif`
 - `image/png`
 - `image/ico`
 - `image/x-icon`
 - `image/bmp`
 - `image/x-bmp`
 - `image/x-xbitmap`
 - `image/x-win-bitmap`
 */
@interface AFImageRequestOperation : AFHTTPRequestOperation {
@private
#if __IPHONE_OS_VERSION_MIN_REQUIRED
    UIImage *_responseImage;
    CGFloat _imageScale;
#elif __MAC_OS_X_VERSION_MIN_REQUIRED
    NSImage *_responseImage;
#endif
}

/**
 An image constructed from the response data. If an error occurs during the request, `nil` will be returned, and the `error` property will be set to the error.
 */
#if __IPHONE_OS_VERSION_MIN_REQUIRED
@property (readonly, nonatomic, retain) UIImage *responseImage;
#elif __MAC_OS_X_VERSION_MIN_REQUIRED
@property (readonly, nonatomic, retain) NSImage *responseImage;
#endif

#if __IPHONE_OS_VERSION_MIN_REQUIRED
/**
 The scale factor used when interpreting the image data to construct `responseImage`. Specifying a scale factor of 1.0 results in an image whose size matches the pixel-based dimensions of the image. Applying a different scale factor changes the size of the image as reported by the size property. This is set to the value of `[[UIScreen mainScreen] scale]` by default, which automatically scales images for retina displays, for instance.
 */
@property (nonatomic, assign) CGFloat imageScale;
#endif

/**
 An image constructed from the response data. If an error occurs during the request, `nil` will be returned, and the `error` property will be set to the error.
 */

/**
 Creates and returns an `AFImageRequestOperation` object and sets the specified success callback.
 
 @param urlRequest The request object to be loaded asynchronously during execution of the operation.
 @param success A block object to be executed when the request finishes successfully. This block has no return value and takes a single arguments, the image created from the response data of the request.
 
 @return A new image request operation
 */
#if __IPHONE_OS_VERSION_MIN_REQUIRED
+ (AFImageRequestOperation *)imageRequestOperationWithRequest:(NSURLRequest *)urlRequest                
                                                      success:(void (^)(UIImage *image))success;
#elif __MAC_OS_X_VERSION_MIN_REQUIRED
+ (AFImageRequestOperation *)imageRequestOperationWithRequest:(NSURLRequest *)urlRequest                
                                                      success:(void (^)(NSImage *image))success;
#endif

/**
 Creates and returns an `AFImageRequestOperation` object and sets the specified success callback.
 
 @param urlRequest The request object to be loaded asynchronously during execution of the operation.
 @param imageProcessingBlock A block object to be executed after the image request finishes successfully, but before the image is returned in the `success` block. This block takes a single argument, the image loaded from the response body, and returns the processed image.
 @param cacheName The cache name to be associated with the image. `AFImageCache` associates objects by URL and cache name, allowing for multiple versions of the same image to be cached.
 @param success A block object to be executed when the request finishes successfully, with a status code in the 2xx range, and with an acceptable content type (e.g. `image/png`). This block has no return value and takes three arguments: the request object of the operation, the response for the request, and the image created from the response data.
 @param failure A block object to be executed when the request finishes unsuccessfully. This block has no return value and takes three arguments: the request object of the operation, the response for the request, and the error associated with the cause for the unsuccessful operation.
 
 @return A new image request operation
 */
#if __IPHONE_OS_VERSION_MIN_REQUIRED
+ (AFImageRequestOperation *)imageRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                         imageProcessingBlock:(UIImage *(^)(UIImage *))imageProcessingBlock
                                                    cacheName:(NSString *)cacheNameOrNil
                                                      success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image))success
                                                      failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure;
#elif __MAC_OS_X_VERSION_MIN_REQUIRED
+ (AFImageRequestOperation *)imageRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                         imageProcessingBlock:(NSImage *(^)(NSImage *))imageProcessingBlock
                                                    cacheName:(NSString *)cacheNameOrNil
                                                      success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSImage *image))success
                                                      failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure;
#endif

@end
