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
#import "AFHTTPClient.h"

/**
  `AFHTTPRequestOperation` is an `NSOperation` subclass that implements the `NSURLConnection` delegate methods, and provides a simple block-based interface to asynchronously get the result and context of that operation finishes.
 
 # Subclassing Notes
 
 In cases where you don't need all of the information provided in the callback, or you want to validate and/or represent it in a different way, it makes sense to create a subclass to define this behavior. 
 
 For instance, `AFJSONRequestOperation` makes a distinction between successful and unsuccessful requests by validating the HTTP status code and content type of the response, and provides separate callbacks for both the succeeding and failing cases. As another example, `AFImageRequestOperation` offers a pared-down callback, with a single block argument that is an image object that was created from the response data.
 
 ## Methods to Subclass
 
 //
 
 ### `NSURLConnection` Delegate Methods
 
 Notably, `AFHTTPRequestOperation` does not implement any of the authentication challenge-related `NSURLConnection` delegate methods.
 
 `AFHTTPRequestOperation` does implement the following `NSURLConnection` delegate methods:
 
 - `connection:didReceiveResponse:`
 - `connection:didReceiveData:`
 - `connectionDidFinishLoading:`
 - `connection:didFailWithError:`
 - `connection:didSendBodyData:totalBytesWritten:totalBytesExpectedToWrite:`
 - `connection:willCacheResponse:`
 
 If you overwrite any of the above methods, be sure to make the call to `super` first, or else it may cause unexpected results.
 
 @see NSOperation
 @see NSURLConnection
 */
@interface AFHTTPRequestOperation : AFURLConnectionOperation <AFHTTPClientOperation> {
@private
    NSIndexSet *_acceptableStatusCodes;
    NSSet *_acceptableContentTypes;
    NSError *_HTTPError;
}

@property (readonly, nonatomic, retain) NSHTTPURLResponse *response;

/**
 Returns an `NSIndexSet` object containing the ranges of acceptable HTTP status codes (http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html) used in operationWithRequest:success and operationWithRequest:success:failure.
 
 By default, this is the range 200 to 299, inclusive.
 */
@property (nonatomic, retain) NSIndexSet *acceptableStatusCodes;
@property (nonatomic, retain) NSSet *acceptableContentTypes;

///---------------------------------------
/// @name Creating HTTP Request Operations
///---------------------------------------

//+ (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)urlRequest
//                                                    success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSData *data))success
//                                                    failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure;

///-------------------------------
/// @name Validating HTTP Response
///-------------------------------

/**
 
 */
- (BOOL)hasAcceptableStatusCode;

/**
 
 */
- (BOOL)hasAcceptableContentType;

@end
