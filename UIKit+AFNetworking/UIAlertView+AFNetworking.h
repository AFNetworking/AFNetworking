// UIAlertView+AFNetworking.h
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

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && !defined(AF_APP_EXTENSIONS)

#import <UIKit/UIKit.h>

@class AFURLConnectionOperation;

/**
 This category adds methods to the UIKit framework's `UIAlertView` class. The methods in this category provide support for automatically showing an alert if a session task or request operation finishes with an error. Alert title and message are filled from the corresponding `localizedDescription` & `localizedRecoverySuggestion` or `localizedFailureReason` of the error.
 */
@interface UIAlertView (AFNetworking)

///-------------------------------------
/// @name Showing Alert for Session Task
///-------------------------------------

/**
 Shows an alert view with the error of the specified session task, if any.

 @param task The session task.
 @param delegate The alert view delegate.
 */
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
+ (void)showAlertViewForTaskWithErrorOnCompletion:(NSURLSessionTask *)task
                                         delegate:(id)delegate;
#endif

/**
 Shows an alert view with the error of the specified session task, if any, with a custom cancel button title and other button titles.

 @param task The session task.
 @param delegate The alert view delegate.
 @param cancelButtonTitle The title of the cancel button or nil if there is no cancel button. Using this argument is equivalent to setting the cancel button index to the value returned by invoking addButtonWithTitle: specifying this title.
 @param otherButtonTitles The title of another button. Using this argument is equivalent to invoking addButtonWithTitle: with this title to add more buttons. Too many buttons can cause the alert view to scroll. For guidelines on the best ways to use an alert in an app, see "Temporary Views". Titles of additional buttons to add to the receiver, terminated with `nil`.
 */
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
+ (void)showAlertViewForTaskWithErrorOnCompletion:(NSURLSessionTask *)task
                                         delegate:(id)delegate
                                cancelButtonTitle:(NSString *)cancelButtonTitle
                                otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;
#endif

///------------------------------------------
/// @name Showing Alert for Request Operation
///------------------------------------------

/**
 Shows an alert view with the error of the specified request operation, if any.

 @param operation The request operation.
 @param delegate The alert view delegate.
 */
+ (void)showAlertViewForRequestOperationWithErrorOnCompletion:(AFURLConnectionOperation *)operation
                                                     delegate:(id)delegate;

/**
 Shows an alert view with the error of the specified request operation, if any, with a custom cancel button title and other button titles.

 @param operation The request operation.
 @param delegate The alert view delegate.
 @param cancelButtonTitle The title of the cancel button or nil if there is no cancel button. Using this argument is equivalent to setting the cancel button index to the value returned by invoking addButtonWithTitle: specifying this title.
 @param otherButtonTitles The title of another button. Using this argument is equivalent to invoking addButtonWithTitle: with this title to add more buttons. Too many buttons can cause the alert view to scroll. For guidelines on the best ways to use an alert in an app, see "Temporary Views". Titles of additional buttons to add to the receiver, terminated with `nil`.
 */
+ (void)showAlertViewForRequestOperationWithErrorOnCompletion:(AFURLConnectionOperation *)operation
                                                     delegate:(id)delegate
                                            cancelButtonTitle:(NSString *)cancelButtonTitle
                                            otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;

@end

#endif
