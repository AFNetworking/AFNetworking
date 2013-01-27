// AFPropertyListRequestOperation.h
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
 `AFPropertyListRequestOperation` is a subclass of `AFHTTPRequestOperation` for downloading and deserializing objects with property list (plist) response data.

 ## Acceptable Content Types

 By default, `AFPropertyListRequestOperation` accepts the following MIME types:

 - `application/x-plist`
 */
@interface AFPropertyListRequestOperation : AFHTTPRequestOperation

///----------------------------
/// @name Getting Response Data
///----------------------------

/**
 An object deserialized from a plist constructed using the response data.
 */
@property (readonly, nonatomic) id responsePropertyList;

///--------------------------------------
/// @name Managing Property List Behavior
///--------------------------------------

/**
 One of the `NSPropertyListMutabilityOptions` options, specifying the mutability of objects deserialized from the property list. By default, this is `NSPropertyListImmutable`.
 */
@property (nonatomic, assign) NSPropertyListReadOptions propertyListReadOptions;

/**
 Creates and returns an `AFPropertyListRequestOperation` object and sets the specified success and failure callbacks.

 @param urlRequest The request object to be loaded asynchronously during execution of the operation
 @param success A block object to be executed when the operation finishes successfully. This block has no return value and takes three arguments: the request sent from the client, the response received from the server, and the object deserialized from a plist constructed using the response data.
 @param failure A block object to be executed when the operation finishes unsuccessfully, or that finishes successfully, but encountered an error while deserializing the object from a property list. This block has no return value and takes three arguments: the request sent from the client, the response received from the server, and the error describing the network or parsing error that occurred.

 @return A new property list request operation
 */
+ (instancetype)propertyListRequestOperationWithRequest:(NSURLRequest *)urlRequest
												success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, id propertyList))success
												failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id propertyList))failure;

@end
