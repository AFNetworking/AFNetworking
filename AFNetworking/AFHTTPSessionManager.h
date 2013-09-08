// AFHTTPClient.h
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

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <Availability.h>

#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <MobileCoreServices/MobileCoreServices.h>
#else
#import <CoreServices/CoreServices.h>
#endif

#import "AFURLSessionManager.h"
#import "AFHTTPRequestOperation.h"
#import "AFSerialization.h"
#import "AFSecurityPolicy.h"

/**
 `AFHTTPClient` encapsulates the common patterns of communicating with an web application over HTTP, including request creation, response serialization, network reachability monitoring, and security, as well as both request operation and session task management.

 ## Subclassing Notes

 In most cases, one should create an `AFHTTPClient` subclass for each website or web application that your application communicates with. It is often useful, also, to define a class method that returns a singleton shared HTTP client in each subclass, that persists authentication credentials and other configuration across the entire application.

 ## Methods to Override

 To change the behavior of all url request construction for an `AFHTTPClient` subclass, override `requestWithMethod:URLString:parameters`.

 To change the behavior of all request operation construction for an `AFHTTPClient` subclass, override `HTTPRequestOperationWithRequest:success:failure`.

 To change the behavior of all data task operation construction, which is also used in the `GET` / `POST` / et al. convenience methods, override `dataTaskWithRequest:success:failure:`.
 
 ## Serialization
 
 Requests created by an HTTP client will contain default headers and encode parameters according to the `requestSerializer` property, which is an object conforming to `<AFURLRequestSerialization>`. Responses received from the server are automatically validated and serialized by the `responseSerializers` property, which is an object conforming to `<AFURLResponseSerialization>`

 ## URL Construction Using Relative Paths

 Both `-requestWithMethod:URLString:parameters:` and `-multipartFormRequestWithMethod:URLString:parameters:constructingBodyWithBlock:` construct URLs from the path relative to the `-baseURL`, using `NSURL +URLWithString:relativeToURL:`, when provided. If `baseURL` is `nil`, `path` needs to resolve to a valid `NSURL` object using `NSURL +URLWithString:`.
 
 Below are a few examples of how `baseURL` and relative paths interact:

    NSURL *baseURL = [NSURL URLWithString:@"http://example.com/v1/"];
    [NSURL URLWithString:@"foo" relativeToURL:baseURL];                  // http://example.com/v1/foo
    [NSURL URLWithString:@"foo?bar=baz" relativeToURL:baseURL];          // http://example.com/v1/foo?bar=baz
    [NSURL URLWithString:@"/foo" relativeToURL:baseURL];                 // http://example.com/foo
    [NSURL URLWithString:@"foo/" relativeToURL:baseURL];                 // http://example.com/v1/foo
    [NSURL URLWithString:@"/foo/" relativeToURL:baseURL];                // http://example.com/foo/
    [NSURL URLWithString:@"http://example2.com/" relativeToURL:baseURL]; // http://example2.com/

 Also important to note is that a trailing slash will be added to any `baseURL` without one. This would otherwise cause unexpected behavior when constructing URLs using paths without a leading slash.
 
 ## Network Reachability Monitoring
 
 Network reachability status and change monitoring is available to any `AFHTTPClient` created with a specified `baseURL`. Applications may choose to monitor network reachability conditions in order to prevent or suspend any outbound requests.
 
 The current reachability status can be accessed with the `networkReachabilityStatus` property. Changes can be monitored by doing `setReachabilityStatusChangeBlock:`, or listening for an `AFNetworkingReachabilityDidChangeNotification` notification.

 ## NSCoding / NSCopying Conformance

 `AFHTTPClient`  conforms to the `NSCoding` and `NSCopying` protocols, allowing operations to be archived to disk, and copied in memory, respectively. There are a few minor caveats to keep in mind, however:

 - Archives and copies of HTTP clients will be initialized with an empty operation queue.
 - NSCoding cannot serialize / deserialize block properties, so an archive of an HTTP client will not include any reachability callback block that may be set.
 */
@interface AFHTTPSessionManager : AFURLSessionManager <NSCoding, NSCopying>

/**
 The URL used to monitor reachability, and construct requests from relative paths in methods like `requestWithMethod:URLString:parameters:`, and the `GET` / `POST` / et al. convenience methods.
 */
@property (readonly, nonatomic, strong) NSURL *baseURL;

/**
 Requests created with `requestWithMethod:URLString:parameters:` & `multipartFormRequestWithMethod:URLString:parameters:constructingBodyWithBlock:` are constructed with a set of default headers using a parameter serialization specified by this property. By default, this is set to an instance of `AFHTTPSerializer`, which serializes query string parameters for `GET`, `HEAD`, and `DELETE` requests, or otherwise URL-form-encodes HTTP message bodies.
 
 @warning `requestSerializer` must not be `nil`.
 */
@property (nonatomic, strong) AFHTTPRequestSerializer <AFURLRequestSerialization> * requestSerializer;

/**
 Responses sent from the server in data tasks created with `dataTaskWithRequest:success:failure:` and run using the `GET` / `POST` / et al. convenience methods are automatically validated and serialized by the response serializer. By default, this property is set to a compound serializer, which serializes data from responses with either a `application/json` or `application/x-plist` MIME type, and falls back to the raw data object. The serializer validates the status code to be in the `2XX` range, denoting success. If the response serializer generates an error in `-responseObjectForResponse:data:error:`, the `failure` callback of the session task or request operation will be executed; otherwise, the `success` callback will be executed.

 @warning `responseSerializer` must not be `nil`.
 */
@property (nonatomic, strong) AFHTTPResponseSerializer <AFURLResponseSerialization> * responseSerializer;

///---------------------------------------------
/// @name Creating and Initializing HTTP Clients
///---------------------------------------------

/**
 Creates and returns an `AFHTTPClient` object.
 */
+ (instancetype)manager;

/**
 Initializes an `AFHTTPClient` object with the specified base URL.
 
 @param url The base URL for the HTTP client.

 @return The newly-initialized HTTP client
 */
- (instancetype)initWithBaseURL:(NSURL *)url;

/**
 Initializes an `AFHTTPClient` object with the specified base URL.

 This is the designated initializer.

 @param url The base URL for the HTTP client.
 @param configuration The configuration used to create the managed session.

 @return The newly-initialized HTTP client
 */
- (instancetype)initWithBaseURL:(NSURL *)url
           sessionConfiguration:(NSURLSessionConfiguration *)configuration;

///---------------------------------------
/// @name Managing HTTP Request Operations
///---------------------------------------

/**
 Creates an `AFHTTPRequestOperation`, setting the operation's request serializer and response serializers to those of the HTTP client.

 @param request The request object to be loaded asynchronously during execution of the operation.
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes two arguments: the created request operation and the object created from the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.
 */
- (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)request
                                                    success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                                    failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**
 Enqueues an `AFHTTPRequestOperation` to the HTTP client's operation queue.

 @param operation The HTTP request operation to be enqueued.
 */
- (void)enqueueHTTPRequestOperation:(AFHTTPRequestOperation *)operation;

/**
 Cancels all operations in the HTTP client's operation queue whose URLs match the specified HTTP method and URL string.

 This method only cancels `AFHTTPRequestOperations` whose request URL matches the HTTP client base URL with the path appended. For complete control over the lifecycle of enqueued operations, you can access the `operationQueue` property directly, which allows you to, for instance, cancel operations filtered by a predicate, or simply use `-cancelAllRequests`. Note that the operation queue may include non-HTTP operations, so be sure to check the type before attempting to directly introspect an operation's `request` property.

 @param method The HTTP method to match for the cancelled requests, such as `GET`, `POST`, `PUT`, or `DELETE`. If `nil`, all request operations with matching URLs will be cancelled.
 @param URLString The URL string used to create the request URL.
 */
- (void)cancelAllHTTPOperationsWithMethod:(NSString *)method
                                URLString:(NSString *)URLString;

- (void)cancelAllHTTPOperationsWithMethod:(NSString *)method
                                     path:(NSString *)path __attribute__((deprecated));

///---------------------------------------
/// @name Batching HTTP Request Operations
///---------------------------------------

/**
 Creates and enqueues an `AFHTTPRequestOperation` to the HTTP client's operation queue for each specified request object into a batch. When each request operation finishes, the specified progress block is executed, until all of the request operations have finished, at which point the completion block also executes.

 Operations are created by passing the specified `NSURLRequest` objects in `requests`, using `-HTTPRequestOperationWithRequest:success:failure:`, with `nil` for both the `success` and `failure` parameters.

 @param requests The `NSURLRequest` objects used to create and enqueue operations.
 @param progressBlock A block object to be executed upon the completion of each request operation in the batch. This block has no return value and takes two arguments: the number of operations that have already finished execution, and the total number of operations.
 @param completionBlock A block object to be executed upon the completion of all of the request operations in the batch. This block has no return value and takes a single argument: the batched request operations.
 */
- (void)enqueueBatchOfHTTPRequestOperationsWithRequests:(NSArray *)requests
                                          progressBlock:(void (^)(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations))progressBlock
                                        completionBlock:(void (^)(NSArray *operations))completionBlock;

/**
 Enqueues the specified request operations into a batch. When each request operation finishes, the specified progress block is executed, until all of the request operations have finished, at which point the completion block also executes.

 @param operations The request operations used to be batched and enqueued.
 @param progressBlock A block object to be executed upon the completion of each request operation in the batch. This block has no return value and takes two arguments: the number of operations that have already finished execution, and the total number of operations.
 @param completionBlock A block object to be executed upon the completion of all of the request operations in the batch. This block has no return value and takes a single argument: the batched request operations.
 */
- (void)enqueueBatchOfHTTPRequestOperations:(NSArray *)operations
                              progressBlock:(void (^)(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations))progressBlock
                            completionBlock:(void (^)(NSArray *operations))completionBlock;

///---------------------------
/// @name Making HTTP Requests
///---------------------------

/**
 Creates and runs an `NSURLSessionDataTask` with a `GET` request.

 @param URLString The URL string used to create the request URL.
 @param parameters The parameters to be encoded according to the client request serializer.
 @param success A block object to be executed when the task finishes successfully. This block has no return value and takes two arguments: the server response, and the response object created by the client response serializer.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes a single arguments: the error describing the network or parsing error that occurred.

 @see -dataTaskWithRequest:success:failure:
 */
- (NSURLSessionDataTask *)GET:(NSString *)URLString
                   parameters:(NSDictionary *)parameters
                      success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                      failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure;

/**
 Creates and runs an `NSURLSessionDataTask` with a `HEAD` request.

 @param URLString The URL string used to create the request URL.
 @param parameters The parameters to be encoded according to the client request serializer.
 @param success A block object to be executed when the task finishes successfully. This block has no return value and takes a single arguments: the server response.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes a single arguments: the error describing the network or parsing error that occurred.

 @see -dataTaskWithRequest:success:failure:
 */
- (NSURLSessionDataTask *)HEAD:(NSString *)URLString
                    parameters:(NSDictionary *)parameters
                       success:(void (^)(NSURLSessionDataTask *task))success
                       failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure;

/**
 Creates and runs an `NSURLSessionDataTask` with a `POST` request.

 @param URLString The URL string used to create the request URL.
 @param parameters The parameters to be encoded according to the client request serializer.
 @param success A block object to be executed when the task finishes successfully. This block has no return value and takes two arguments: the server response, and the response object created by the client response serializer.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes a single arguments: the error describing the network or parsing error that occurred.

 @see -dataTaskWithRequest:success:failure:
 */
- (NSURLSessionDataTask *)POST:(NSString *)URLString
                    parameters:(NSDictionary *)parameters
                       success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                       failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure;

/**
 Creates and runs an `NSURLSessionDataTask` with a multipart `POST` request.

 @param URLString The URL string used to create the request URL.
 @param parameters The parameters to be encoded according to the client request serializer.
 @param block A block that takes a single argument and appends data to the HTTP body. The block argument is an object adopting the `AFMultipartFormData` protocol.
 @param success A block object to be executed when the task finishes successfully. This block has no return value and takes two arguments: the server response, and the response object created by the client response serializer.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes a single arguments: the error describing the network or parsing error that occurred.

 @see -dataTaskWithRequest:success:failure:
 */
- (NSURLSessionDataTask *)POST:(NSString *)URLString
                    parameters:(NSDictionary *)parameters
     constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
                       success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                       failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure;

/**
 Creates and runs an `NSURLSessionDataTask` with a `PUT` request.

 @param URLString The URL string used to create the request URL.
 @param parameters The parameters to be encoded according to the client request serializer.
 @param success A block object to be executed when the task finishes successfully. This block has no return value and takes two arguments: the server response, and the response object created by the client response serializer.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes a single arguments: the error describing the network or parsing error that occurred.

 @see -dataTaskWithRequest:success:failure:
 */
- (NSURLSessionDataTask *)PUT:(NSString *)URLString
                   parameters:(NSDictionary *)parameters
                      success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                      failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure;

/**
 Creates and runs an `NSURLSessionDataTask` with a `PATCH` request.

 @param URLString The URL string used to create the request URL.
 @param parameters The parameters to be encoded according to the client request serializer.
 @param success A block object to be executed when the task finishes successfully. This block has no return value and takes two arguments: the server response, and the response object created by the client response serializer.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes a single arguments: the error describing the network or parsing error that occurred.

 @see -dataTaskWithRequest:success:failure:
 */
- (NSURLSessionDataTask *)PATCH:(NSString *)URLString
                     parameters:(NSDictionary *)parameters
                        success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                        failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure;

/**
 Creates and runs an `NSURLSessionDataTask` with a `DELETE` request.

 @param URLString The URL string used to create the request URL.
 @param parameters The parameters to be encoded according to the client request serializer.
 @param success A block object to be executed when the task finishes successfully. This block has no return value and takes two arguments: the server response, and the response object created by the client response serializer.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes a single arguments: the error describing the network or parsing error that occurred.

 @see -dataTaskWithRequest:success:failure:
 */
- (NSURLSessionDataTask *)DELETE:(NSString *)URLString
                      parameters:(NSDictionary *)parameters
                         success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                         failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure;

@end

