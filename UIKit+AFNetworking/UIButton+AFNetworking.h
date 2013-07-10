// UIButton+AFNetworking.h
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

#import <Availability.h>
#import <AVFoundation/AVFoundation.h>


#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <UIKit/UIKit.h>

/**
 
 */
@interface UIButton (AFNetworking)

///--------------------
/// @name Setting Image
///--------------------

/**
 
 */
- (void)setImageForState:(UIControlState)state
                 withURL:(NSURL *)url;

/**
 
 */
- (void)setImageForState:(UIControlState)state
                 withURL:(NSURL *)url
        placeholderImage:(UIImage *)placeholderImage;

/**
 
 */
- (void)setImageForState:(UIControlState)state
          withURLRequest:(NSURLRequest *)urlRequest
        placeholderImage:(UIImage *)placeholderImage
                 success:(void (^)(NSHTTPURLResponse *response, UIImage *image))success
                 failure:(void (^)(NSError *error))failure;


///-------------------------------
/// @name Setting Background Image
///-------------------------------

/**
 
 */
- (void)setBackgroundImageForState:(UIControlState)state
                           withURL:(NSURL *)url;

/**
 
 */
- (void)setBackgroundImageForState:(UIControlState)state
                           withURL:(NSURL *)url
                  placeholderImage:(UIImage *)image;

/**
 
 */
- (void)setBackgroundImageForState:(UIControlState)state
                    withURLRequest:(NSURLRequest *)urlRequest
                  placeholderImage:(UIImage *)placeholderImage
                           success:(void (^)(NSHTTPURLResponse *response, UIImage *image))success
                           failure:(void (^)(NSError *error))failure;


///-------------------------------
/// @name Cancelling Image Loading
///-------------------------------

/**
 
 */
- (void)cancelImageDataTasks;

@end

#endif
