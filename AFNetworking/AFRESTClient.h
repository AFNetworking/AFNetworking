// AFRESTClient.h
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

@protocol AFMultipartFormDataProxy;

@interface AFRESTClient : NSObject {
@private
    NSURL *_baseURL;
    NSStringEncoding _stringEncoding;
    NSMutableDictionary *_defaultHeaders;
    NSOperationQueue *_operationQueue;
}

/**
 The url used as the base for paths specified in methods such as `getPath:parameteres:success:failure`
 */
@property (readonly, nonatomic, retain) NSURL *baseURL;

/**
 The string encoding used in constructing url requests. This is `NSUTF8StringEncoding` by default.
 */
@property (nonatomic, assign) NSStringEncoding stringEncoding;

/**
 The operation queue which manages operations enqueued by the REST client.
 */
@property (readonly, nonatomic, retain) NSOperationQueue *operationQueue;;

///--------------------------------
/// @name Initializing REST Clients
///--------------------------------

/**
 Initializes an `AFRestClient` object with the specified base URL.
 
 @param url The base URL for the REST client. This argument must not be nil.
 
 @return The newly-initialized REST client
 */
- (id)initWithBaseURL:(NSURL *)url;

///----------------------------------
/// @name Managing HTTP Header Values
///----------------------------------

/**
 Returns the value for the HTTP headers set in request objects created by the REST client
 
 @param header The HTTP header to return the default value for
 
 @return The default value for the HTTP header, or `nil` if unspecified
 */
- (NSString *)defaultValueForHeader:(NSString *)header;

/**
 Sets the value for the HTTP headers set in request objects made by the REST client. If `nil`, removes the existing value for that header.
 
 @param header The HTTP header to set a default value for
 @param value The value set as default for the specified header, or `nil
 */
- (void)setDefaultHeader:(NSString *)header value:(NSString *)value;

/**
 Sets the "Authorization" HTTP header set in request objects made by the REST client to a basic authentication value with Base64-encoded username and password. This overwrites any existing value for this header.
 
 @param username The HTTP basic auth username
 @param password The HTTP basic auth password
 */
- (void)setAuthorizationHeaderWithUsername:(NSString *)username password:(NSString *)password;

/**
 Sets the "Authorization" HTTP header set in request objects made by the REST client to a token-based authentication value, such as an OAuth access token. This overwrites any existing value for this header.
 
 @param token The authentication token
 */
- (void)setAuthorizationHeaderWithToken:(NSString *)token;

/**
 Clears any existing value for the "Authorization" HTTP header.
 */
- (void)clearAuthorizationHeader;

///-------------------------------
/// @name Creating Request Objects
///-------------------------------

/**
 Creates an `NSMutableURLRequest` object with the specified HTTP method and resource path. If the HTTP method is `GET`, the parameters will be used to construct a url-encoded query string that is appended to the request's URL. If `POST`, `PUT`, or `DELETE`, the parameters will be encoded into a `application/x-www-form-urlencoded` HTTP body.
 
 @param method The HTTP method for the request, such as `GET`, `POST`, `PUT`, or `DELETE`.
 @param path The resource path to be appended to the REST client's base URL and used as the request URL.
 @param parameters The parameters to be either set as a query string for `GET` requests, or the request HTTP body.
 
 @return An `NSMutableURLRequest` object
 */
- (NSMutableURLRequest *)requestWithMethod:(NSString *)method 
                                      path:(NSString *)path parameters:(NSDictionary *)parameters;

/**
 Creates an `NSMutableURLRequest` object with the specified HTTP method and resource path, and constructs a `multipart/form-data` HTTP body, using the specified parameters and multipart form data block.
 
 @param method The HTTP method for the request. Must be either `POST`, `PUT`, or `DELETE`.
 @param path The resource path to be appended to the REST client's base URL and used as the request URL.
 @param parameters The parameters to be encoded and set in the request HTTP body.
 @param block A block that takes a single argument and appends data to the HTTP body. The block argument is an object adopting the `AFMultipartFormDataProxy` protocol. This can be used to upload files, encode HTTP body as JSON or XML, or specify multiple values for the same parameter, as one might for array values.
 
 @see AFMultipartFormDataProxy
 
 @return An `NSMutableURLRequest` object
 */
- (NSMutableURLRequest *)multipartFormRequestWithMethod:(NSString *)method
                                                   path:(NSString *)path
                                             parameters:(NSDictionary *)parameters
                              constructingBodyWithBlock:(void (^)(id <AFMultipartFormDataProxy>formData))block;


///--------------------------------
/// @name Enqueuing HTTP Operations
///--------------------------------

/**
 Constructs and enqueues an `AFHTTPRequestOperation` to the REST client's operation queue.
 
 @param request The request object to be loaded asynchronously during execution of the operation.
 @param success A block object to be executed when the request operation finishes successfully, with a status code in the 2xx range, and with an acceptable content types (e.g. `application/json`). This block has no return value and takes a single argument, which is the response object created from the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the resonse data as JSON. This block has no return value and takes a single argument, which is the `NSError` object describing the network or parsing error that occurred.
 */
- (void)enqueueHTTPOperationWithRequest:(NSURLRequest *)request 
                                success:(void (^)(id response))success 
                                failure:(void (^)(NSError *error))failure;

///---------------------------------
/// @name Cancelling HTTP Operations
///---------------------------------

/**
 Cancels all operations in the REST client's operation queue that match the specified HTTP method and URL.
 
 @param method The HTTP method to match for the cancelled requests, such as `GET`, `POST`, `PUT`, or `DELETE`.
 @param url The URL to match for the cancelled requests.
 */
- (void)cancelHTTPOperationsWithMethod:(NSString *)method andURL:(NSURL *)url;

///---------------------------
/// @name Making HTTP Requests
///---------------------------
- (void)getPath:(NSString *)path
     parameters:(NSDictionary *)parameters
        success:(void (^)(id response))success
        failure:(void (^)(NSError *error))failure;

- (void)postPath:(NSString *)path 
      parameters:(NSDictionary *)parameters 
         success:(void (^)(id response))success 
         failure:(void (^)(NSError *error))failure;

- (void)putPath:(NSString *)path 
     parameters:(NSDictionary *)parameters 
        success:(void (^)(id response))success 
        failure:(void (^)(NSError *error))failure;

- (void)deletePath:(NSString *)path 
        parameters:(NSDictionary *)parameters 
           success:(void (^)(id response))success 
           failure:(void (^)(NSError *error))failure;
@end

#pragma mark -

@protocol AFMultipartFormDataProxy <NSObject>
- (void)appendPartWithHeaders:(NSDictionary *)headers body:(NSData *)body;
- (void)appendPartWithFormData:(NSData *)data name:(NSString *)name;
- (void)appendPartWithFile:(NSURL *)fileURL fileName:(NSString *)fileNameOrNil;
- (void)appendData:(NSData *)data;
- (void)appendString:(NSString *)string;
@end
