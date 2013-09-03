// UIAlertView+AFNetworking.h
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

#import <UIKit/UIKit.h>

#import "AFURLConnectionOperation.h"
#import "AFURLSessionManager.h"

/**
 
 */
@interface UIAlertView (AFNetworking)

///-------------------------------------
/// @name Showing Alert for Session Task
///-------------------------------------

/**

 */
+ (void)showAlertViewForTaskWithErrorOnCompletion:(NSURLSessionTask *)task
                                         delegate:(id /*<UIAlertViewDelegate>*/)delegate;

/**
 
 */
+ (void)showAlertViewForTaskWithErrorOnCompletion:(NSURLSessionTask *)task
                                         delegate:(id /*<UIAlertViewDelegate>*/)delegate
                                cancelButtonTitle:(NSString *)cancelButtonTitle
                                otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;


///------------------------------------------
/// @name Showing Alert for Request Operation
///------------------------------------------

/**
 
 */
+ (void)showAlertViewForRequestOperationWithErrorOnCompletion:(AFURLConnectionOperation *)operation
                                                     delegate:(id /*<UIAlertViewDelegate>*/)delegate;

/**
 
 */
+ (void)showAlertViewForRequestOperationWithErrorOnCompletion:(AFURLConnectionOperation *)operation
                                                     delegate:(id /*<UIAlertViewDelegate>*/)delegate
                                            cancelButtonTitle:(NSString *)cancelButtonTitle
                                            otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;

@end
