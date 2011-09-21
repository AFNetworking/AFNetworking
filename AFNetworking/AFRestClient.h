// AFRestClient.h
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

@interface AFRestClient : NSObject {
@private
    NSURL *_baseURL;
    NSStringEncoding _stringEncoding;
    NSMutableDictionary *_defaultHeaders;
    NSOperationQueue *_operationQueue;
}

/**
 An `NSURL` object that is used as the base for paths specified in methods such as `getPath:parameteres:success:failure`
 */
@property (readonly, nonatomic, retain) NSURL *baseURL;

@property (nonatomic, assign) NSStringEncoding stringEncoding;

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
 Creates an `NSMutableURLRequest` object with the specified HTTP method, resource path, and parameters, with the default HTTP headers specified for the client.
 
 @param method The HTTP method for the request, such as `GET`, `POST`, `PUT`, or `DELETE`
 @param path The resource path to be appended to the REST client's base URL and used as the request URL
 @param parameters The parameters to be either set as a query string for `GET` requests, or form URL-encoded and set in the request HTTP body
 
 @return An `NSMutableURLRequest` object
 */
- (NSMutableURLRequest *)requestWithMethod:(NSString *)method 
                                      path:(NSString *)path parameters:(NSDictionary *)parameters;

- (NSMutableURLRequest *)multipartFormRequestWithMethod:(NSString *)method
                                                   path:(NSString *)path
                                             parameters:(NSDictionary *)parameters
                              constructingBodyWithBlock:(void (^)(id <AFMultipartFormDataProxy>formData))block;


///--------------------------------
/// @name Enqueuing HTTP Operations
///--------------------------------
- (void)enqueueHTTPOperation:(AFHTTPRequestOperation *)operation;

- (void)enqueueHTTPOperationWithRequest:(NSURLRequest *)request 
                                success:(void (^)(id response))success 
                                failure:(void (^)(NSError *error))failure;

///---------------------------------
/// @name Cancelling HTTP Operations
///---------------------------------

- (void)cancelHTTPOperationsWithRequest:(NSURLRequest *)request;

- (void)cancelAllHTTPOperations;

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
