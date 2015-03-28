// UIActivityIndicatorView+AFNetworking.h
//
// Copyright (c) 2013-2015 AFNetworking (http://afnetworking.com)
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

@class AFURLConnectionOperation;

/**
 This category adds methods to the UIKit framework's `UIActivityIndicatorView` class. The methods in this category provide support for automatically starting and stopping animation depending on the loading state of a request operation or session task.
 */
@interface UIActivityIndicatorView (AFNetworking)

///----------------------------------
/// @name Animating for Session Tasks
///----------------------------------

/**
 Binds the animating state to the state of the specified task.

 @param task The task. If `nil`, automatic updating from any previously specified operation will be disabled.
 */
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
- (void)setAnimatingWithStateOfTask:(NSURLSessionTask *)task;
#endif

///---------------------------------------
/// @name Animating for Request Operations
///---------------------------------------

/**
 Binds the animating state to the execution state of the specified operation.

 @param operation The operation. If `nil`, automatic updating from any previously specified operation will be disabled.
 */
- (void)setAnimatingWithStateOfOperation:(AFURLConnectionOperation *)operation;

@end

#endif
