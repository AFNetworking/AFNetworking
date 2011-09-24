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
#import <UIKit/UIKit.h>
#import "AFHTTPRequestOperation.h"

/**
 `AFImageRequestOperation` is an `NSOperation` that wraps the callback from `AFHTTPRequestOperation` to create an image from the response body, and optionally cache the image to memory.
 
 @see NSOperation
 @see AFHTTPRequestOperation
 */
@interface AFImageRequestOperation : AFHTTPRequestOperation

/**
 Creates and returns an `AFImageRequestOperation` object and sets the specified success callback.
 
 @param urlRequest The request object to be loaded asynchronously during execution of the operation.
 @param success A block object to be executed when the request finishes successfully, with a status code in the 2xx range, and with an acceptable content type (e.g. `image/png`). This block has no return value and takes a single arguments, the image created from the response data of the request.
 
 @return A new image request operation
 */
+ (AFImageRequestOperation *)operationWithRequest:(NSURLRequest *)urlRequest                
                                          success:(void (^)(UIImage *image))success;

/**
 Creates and returns an `AFImageRequestOperation` object and sets the specified success callback.
 
 @param urlRequest The request object to be loaded asynchronously during execution of the operation.
 @param imageProcessingBlock A block object to be executed after the image request finishes successfully, but before the image is returned in the `success` block. This block takes a single argument, the image loaded from the response body, and returns the processed image.
 @param cacheName The cache name to be associated with the image. `AFImageCache` associates objects by URL and cache name, allowing for multiple versions of the same image to be cached.
 @param success A block object to be executed when the request finishes successfully, with a status code in the 2xx range, and with an acceptable content type (e.g. `image/png`). This block has no return value and takes three arguments: the request object of the operation, the response for the request, and the image created from the response data.
 @param failure A block object to be executed when the request finishes unsuccessfully. This block has no return value and takes three arguments: the request object of the operation, the response for the request, and the error associated with the cause for the unsuccessful operation.
 
 @return A new image request operation
 */
+ (AFImageRequestOperation *)operationWithRequest:(NSURLRequest *)urlRequest
                             imageProcessingBlock:(UIImage *(^)(UIImage *))imageProcessingBlock
                                        cacheName:(NSString *)cacheNameOrNil
                                          success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image))success
                                          failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure;

@end
