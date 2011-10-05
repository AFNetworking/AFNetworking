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
 `AFJSONRequestOperation` is an `NSOperation` that wraps the callback from `AFHTTPRequestOperation` to determine the success or failure of a request based on its status code and response content type, and parse the response body into a JSON object.
 
 @see NSOperation
 @see AFHTTPRequestOperation
 */
@interface AFJSONRequestOperation : AFHTTPRequestOperation {
@private
    id _responseJSON;
    NSError *_JSONError;
}

@property (readonly, nonatomic, retain) id responseJSON;

///---------------------------------------
/// @name Creating JSON Request Operations
///---------------------------------------

/**
 Creates and returns an `AFJSONRequestOperation` object and sets the specified success and failure callbacks, as well as the status codes and content types that are acceptable for a successful request.
 
 @param urlRequest The request object to be loaded asynchronously during execution of the operation
 @param acceptableStatusCodes An `NSIndexSet` object that specifies the ranges of acceptable status codes. If you specify nil, all status codes will be considered acceptable.
 @param acceptableContentTypes An `NSSet` object that specifies the acceptable content types. If you specify nil, all content types will be considered acceptable.
 @param success A block object to be executed when the JSON request operation finishes successfully, with a status code in the 2xx range, and with an acceptable content type (e.g. `application/json`). This block has no return value and takes three arguments, the request sent from the client, the response received from the server, and the JSON object created from the response data of request.
 @param failure A block object to be executed when the JSON request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the resonse data as JSON. This block has no return value and takes three arguments, the request sent from the client, the response received from the server, and the error describing the network or parsing error that occurred.
  
 @return A new JSON request operation
 */
+ (AFJSONRequestOperation *)JSONRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                                    success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, id JSON))success
                                                    failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure;
@end
