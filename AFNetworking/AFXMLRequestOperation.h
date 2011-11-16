// AFXMLRequestOperation.h
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

#import <Availability.h>

/**
 `AFXMLRequestOperation` is a subclass of `AFHTTPRequestOperation` for downloading and working with XML response data.
 
 ## Acceptable Content Types
 
 By default, `AFXMLRequestOperation` accepts the following MIME types, which includes the official standard, `application/xml`, as well as other commonly-used types:
 
 - `application/xml`
 - `text/xml`
 
 ## Use With AFHTTPClient
 
 When `AFXMLRequestOperation` is registered with `AFHTTPClient`, the response object in the success callback of `HTTPRequestOperationWithRequest:success:failure:` will be an instance of `NSXMLParser`. On platforms that support `NSXMLDocument`, you have the option to ignore the response object, and simply use the `responseXMLDocument` property of the operation argument of the callback.
 */
@interface AFXMLRequestOperation : AFHTTPRequestOperation {
@private
    NSXMLParser *_responseXMLParser;
}

///----------------------------
/// @name Getting Response Data
///----------------------------

/**
 An `NSXMLParser` object constructed from the response data.
 */
@property (readonly, nonatomic, retain) NSXMLParser *responseXMLParser;


/**
 Creates and returns an `AFXMLRequestOperation` object and sets the specified success and failure callbacks.
 
 @param urlRequest The request object to be loaded asynchronously during execution of the operation
 @param success A block object to be executed when the operation finishes successfully. This block has no return value and takes three arguments: the request sent from the client, the response received from the server, and the XML parser constructed with the response data of request.
 @param failure A block object to be executed when the operation finishes unsuccessfully. This block has no return value and takes three arguments: the request sent from the client, the response received from the server, and the error describing the network error that occurred.
 
 @return A new XML request operation
 */
+ (AFXMLRequestOperation *)XMLParserRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                                        success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSXMLParser *XMLParser))success
                                                        failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, NSXMLParser *XMLParse))failure;


@end
