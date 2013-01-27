// AFJSONRequestOperation.h
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

/**
 `AFJSONRequestOperation` is a subclass of `AFHTTPRequestOperation` for downloading and working with JSON response data.
 
 ## Acceptable Content Types
 
 By default, `AFJSONRequestOperation` accepts the following MIME types, which includes the official standard, `application/json`, as well as other commonly-used types:
 
 - `application/json`
 - `text/json`

 @warning JSON parsing will use the built-in `NSJSONSerialization` class.
 */
@interface AFJSONRequestOperation : AFHTTPRequestOperation

///----------------------------
/// @name Getting Response Data
///----------------------------

/**
 A JSON object constructed from the response data. If an error occurs while parsing, `nil` will be returned, and the `error` property will be set to the error.
 */
@property (readonly, nonatomic, strong) id responseJSON;

/**
 Options for reading the response JSON data and creating the Foundation objects. For possible values, see the `NSJSONSerialization` documentation section "NSJSONReadingOptions".
 */
@property (nonatomic, assign) NSJSONReadingOptions JSONReadingOptions;
 
///----------------------------------
/// @name Creating Request Operations
///----------------------------------

/**
 Creates and returns an `AFJSONRequestOperation` object and sets the specified success and failure callbacks.
 
 @param urlRequest The request object to be loaded asynchronously during execution of the operation
 @param success A block object to be executed when the operation finishes successfully. This block has no return value and takes three arguments: the request sent from the client, the response received from the server, and the JSON object created from the response data of request.
 @param failure A block object to be executed when the operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data as JSON. This block has no return value and takes three arguments: the request sent from the client, the response received from the server, and the error describing the network or parsing error that occurred.
  
 @return A new JSON request operation
 */
+ (instancetype)JSONRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                        success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, id JSON))success
                                        failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON))failure;

@end
