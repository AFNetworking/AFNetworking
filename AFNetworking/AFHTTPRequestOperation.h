// AFHTTPOperation.h
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
#import "AFURLConnectionOperation.h"

@class AFHTTPRequestOperation;

/**
 `AFHTTPRequestOperation` is a subclass of `AFURLConnectionOperation` for requests using the HTTP or HTTPS protocols. It encapsulates the concept of acceptable status codes and content types, which determine the success or failure of a request.
 */
@interface AFHTTPRequestOperation : AFURLConnectionOperation {
@private
    NSIndexSet *_acceptableStatusCodes;
    NSSet *_acceptableContentTypes;
    NSError *_HTTPError;
    dispatch_queue_t _callbackQueue;
    
    void (^_completionBlock)(void);
    void (^finishedBlock)(void);
#if __IPHONE_OS_VERSION_MIN_REQUIRED
    BOOL _attemptToContinueWhenAppEntersBackground;
    UIBackgroundTaskIdentifier _backgroundTask;
#endif
    
}

///----------------------------------------------
/// @name Getting HTTP URL Connection Information
///----------------------------------------------

/**
 The last HTTP response received by the operation's connection.
 */
@property (readonly, nonatomic, retain) NSHTTPURLResponse *response;

/**
 The last HTTP error received by the operation's connection.
 */
@property (readonly, nonatomic, retain) NSError *HTTPError;



#if __IPHONE_OS_VERSION_MIN_REQUIRED
///-------------------------------
/// @name iOS Multitasking Support
///-------------------------------

/**
 Attempt to prevent the application from shutting down until the response has been completed. 
 (You probably want to wrap your operation queue as well to stop when it;s completed.)
 */

@property (nonatomic, assign) BOOL attemptToContinueWhenAppEntersBackground;
#endif

///----------------------------------------------------------
/// @name Managing And Checking For Acceptable HTTP Responses
///----------------------------------------------------------

/**
 Returns an `NSIndexSet` object containing the ranges of acceptable HTTP status codes. When non-`nil`, the operation will set the `error` property to an error in `AFErrorDomain`. See http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html
 
 By default, this is the range 200 to 299, inclusive.
 */
@property (nonatomic, retain) NSIndexSet *acceptableStatusCodes;

/**
 A Boolean value that corresponds to whether the status code of the response is within the specified set of acceptable status codes. Returns `YES` if `acceptableStatusCodes` is `nil`.
 */
@property (readonly) BOOL hasAcceptableStatusCode;

/**
 Returns an `NSSet` object containing the acceptable MIME types. When non-`nil`, the operation will set the `error` property to an error in `AFErrorDomain`. See http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.17 
 
 By default, this is `nil`.
 */
@property (nonatomic, retain) NSSet *acceptableContentTypes;

/**
 A Boolean value that corresponds to whether the MIME type of the response is among the specified set of acceptable content types. Returns `YES` if `acceptableContentTypes` is `nil`.
 */
@property (readonly) BOOL hasAcceptableContentType;


///-----------------------
/// @name Subclass methods
///-----------------------

/**
 A Boolean value determining whether or not the class can process the specified request. For example, `AFJSONRequestOperation` may check to make sure the content type was `application/json` or the URL path extension was `.json`.
 
 @param urlRequest The request that is determined to be supported or not supported for this class.
 */
+ (BOOL)canProcessRequest:(NSURLRequest *)urlRequest;


/** 
 Returns decoded response as a generic object.
 */

@property (readonly, nonatomic) id responseObject;


///-------------------------------
/// @name Operation callbacks
///-------------------------------

/**
 Similar to the completetionBlock except that the response is returned on the queue specified in the callbackQueue property.
 */

@property (nonatomic, copy) void(^finishedBlock)(void);


/** 
 The callback dispatch queue. By default this is the calling queue that created the operation. 
 */
@property (nonatomic) dispatch_queue_t callbackQueue;


@end
