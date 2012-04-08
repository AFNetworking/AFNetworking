// AFHTTPClient.h
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

@class AFHTTPRequestOperation;
@protocol AFHTTPClientOperation;
@protocol AFMultipartFormData;

/**
 Posted when network reachability changes.
 The notification object is an `NSNumber` object containing the boolean value for the current network reachability.
 This notification contains no information in the `userInfo` dictionary.
 
 @warning In order for network reachability to be monitored, include the `SystemConfiguration` framework in the active target's "Link Binary With Library" build phase, and add `#import <SystemConfiguration/SystemConfiguration.h>` to the header prefix of the project (Prefix.pch).
 */
#ifdef _SYSTEMCONFIGURATION_H
extern NSString * const AFNetworkingReachabilityDidChangeNotification;
#endif

/**
 Specifies network reachability of the client to its `baseURL` domain.
 */
#ifdef _SYSTEMCONFIGURATION_H
typedef enum {
    AFNetworkReachabilityStatusUnknown          = -1,
    AFNetworkReachabilityStatusNotReachable     = 0,
    AFNetworkReachabilityStatusReachableViaWWAN = 1,
    AFNetworkReachabilityStatusReachableViaWiFi = 2,
} AFNetworkReachabilityStatus;
#endif

/**
 Specifies the method used to encode parameters into request body. 
 */
typedef enum {
    AFFormURLParameterEncoding,
    AFJSONParameterEncoding,
    AFPropertyListParameterEncoding,
} AFHTTPClientParameterEncoding;

/**
 Returns a string, replacing certain characters with the equivalent percent escape sequence based on the specified encoding.
 
 @param string The string to URL encode
 @param encoding The encoding to use for the replacement. If you are uncertain of the correct encoding, you should use UTF-8 (NSUTF8StringEncoding), which is the encoding designated by RFC 3986 as the correct encoding for use in URLs.
 
 @discussion The characters escaped are all characters that are not legal URL characters (based on RFC 3986), including any whitespace, punctuation, or special characters.
 
 @return A URL-encoded string. If it does not need to be modified (no percent escape sequences are missing), this function may merely return string argument.
 */
extern NSString * AFURLEncodedStringFromStringWithEncoding(NSString *string, NSStringEncoding encoding);

/**
 Returns a query string constructed by a set of parameters, using the specified encoding.
 
 @param parameters The parameters used to construct the query string
 @param encoding The encoding to use in constructing the query string. If you are uncertain of the correct encoding, you should use UTF-8 (NSUTF8StringEncoding), which is the encoding designated by RFC 3986 as the correct encoding for use in URLs.
 
 @discussion Query strings are constructed by collecting each key-value pair, URL-encoding a string representation of the key-value pair, and then joining the components with "&". 
 
 
 If a key-value pair has a an `NSArray` for its value, each member of the array will be represented in the format `key[]=value1&key[]value2`. Otherwise, the key-value pair will be formatted as "key=value". String representations of both keys and values are derived using the `-description` method. The constructed query string does not include the ? character used to delimit the query component.
 
 @return A URL-encoded query string
 */
extern NSString * AFQueryStringFromParametersWithEncoding(NSDictionary *parameters, NSStringEncoding encoding);

/**
 `AFHTTPClient` captures the common patterns of communicating with an web application over HTTP. It encapsulates information like base URL, authorization credentials, and HTTP headers, and uses them to construct and manage the execution of HTTP request operations.
 
 ## Automatic Content Parsing
 
 Instances of `AFHTTPClient` may specify which types of requests it expects and should handle by registering HTTP operation classes for automatic parsing. Registered classes will determine whether they can handle a particular request, and then construct a request operation accordingly in `enqueueHTTPRequestOperationWithRequest:success:failure`. See `AFHTTPClientOperation` for further details.
 
 ## Subclassing Notes
 
 In most cases, one should create an `AFHTTPClient` subclass for each website or web application that your application communicates with. It is often useful, also, to define a class method that returns a singleton shared HTTP client in each subclass, that persists authentication credentials and other configuration across the entire application.
 
 ## Methods to Override
 
 To change the behavior of all url request construction for an `AFHTTPClient` subclass, override `requestWithMethod:path:parameters`.
 
 To change the behavior of all request operation construction for an `AFHTTPClient` subclass, override `enqueueHTTPRequestOperationWithRequest:success:failure`.
 
 ## Default Headers
 
 By default, `AFHTTPClient` sets the following HTTP headers:
 
 - `Accept-Encoding: gzip`
 - `Accept-Language: ([NSLocale preferredLanguages]), en-us;q=0.8`
 - `User-Agent: (generated user agent)`
 
 You can override these HTTP headers or define new ones using `setDefaultHeader:value:`.
 
 ## URL Construction Using Relative Paths
 
 Both `requestWithMethod:path:parameters` and `multipartFormRequestWithMethod:path:parameters:constructingBodyWithBlock:` construct URLs from the path relative to the `baseURL`, using `NSURL +URLWithString:relativeToURL:`. Below are a few examples of how `baseURL` and relative paths interract:
 
    NSURL *baseURL = [NSURL URLWithString:@"http://example.com/v1/"];
    [NSURL URLWithString:@"foo" relativeToURL:baseURL];                     // http://example.com/v1/foo
    [NSURL URLWithString:@"foo?bar=baz" relativeToURL:baseURL];             // http://example.com/v1/foo?bar=baz
    [NSURL URLWithString:@"/foo" relativeToURL:baseURL];                    // http://example.com/foo
    [NSURL URLWithString:@"foo/" relativeToURL:baseURL];                    // http://example.com/v1/foo
    [NSURL URLWithString:@"/foo/" relativeToURL:baseURL];                   // http://example.com/foo/
    [NSURL URLWithString:@"http://example2.com/" relativeToURL:baseURL];    // http://example2.com/

 */
@interface AFHTTPClient : NSObject

///---------------------------------------
/// @name Accessing HTTP Client Properties
///---------------------------------------

/**
 The url used as the base for paths specified in methods such as `getPath:parameteres:success:failure`
 */
@property (readonly, nonatomic, retain) NSURL *baseURL;

/**
 The string encoding used in constructing url requests. This is `NSUTF8StringEncoding` by default.
 */
@property (nonatomic, assign) NSStringEncoding stringEncoding;

/**
 The `AFHTTPClientParameterEncoding` value corresponding to how parameters are encoded into a request body. This is `AFFormURLParameterEncoding` by default.

 @warning JSON encoding will automatically use JSONKit, SBJSON, YAJL, or NextiveJSON, if provided. Otherwise, the built-in `NSJSONSerialization` class is used, if available (iOS 5.0 and Mac OS 10.7). If the build target does not either support `NSJSONSerialization` or include a third-party JSON library, a runtime exception will be thrown when attempting to encode parameters as JSON.
 */
@property (nonatomic, assign) AFHTTPClientParameterEncoding parameterEncoding;

/**
 The operation queue which manages operations enqueued by the HTTP client.
 */
@property (readonly, nonatomic, retain) NSOperationQueue *operationQueue;

/**
 The reachability status from the device to the current `baseURL` of the `AFHTTPClient`.

  @warning This property requires the `SystemConfiguration` framework. Add it in the active target's "Link Binary With Library" build phase, and add `#import <SystemConfiguration/SystemConfiguration.h>` to the header prefix of the project (Prefix.pch).
 */
#ifdef _SYSTEMCONFIGURATION_H
@property (readonly, nonatomic, assign) AFNetworkReachabilityStatus networkReachabilityStatus;
#endif

///---------------------------------------------
/// @name Creating and Initializing HTTP Clients
///---------------------------------------------

/**
 Creates and initializes an `AFHTTPClient` object with the specified base URL.
 
 @param url The base URL for the HTTP client. This argument must not be nil.
  
 @return The newly-initialized HTTP client
 */
+ (AFHTTPClient *)clientWithBaseURL:(NSURL *)url;

/**
 Initializes an `AFHTTPClient` object with the specified base URL.
 
 @param url The base URL for the HTTP client. This argument must not be nil.
 
 @discussion This is the designated initializer.
 
 @return The newly-initialized HTTP client
 */
- (id)initWithBaseURL:(NSURL *)url;

///-----------------------------------
/// @name Managing Reachability Status
///-----------------------------------

/**
 Sets a callback to be executed when the network availability of the `baseURL` host changes.
 
 @param block A block object to be executed when the network availability of the `baseURL` host changes.. This block has no return value and takes a single argument which represents the various reachability states from the device to the `baseURL`.
 
 @warning This method requires the `SystemConfiguration` framework. Add it in the active target's "Link Binary With Library" build phase, and add `#import <SystemConfiguration/SystemConfiguration.h>` to the header prefix of the project (Prefix.pch).
 */
#ifdef _SYSTEMCONFIGURATION_H
- (void)setReachabilityStatusChangeBlock:(void (^)(AFNetworkReachabilityStatus status))block;
#endif

///-------------------------------
/// @name Managing HTTP Operations
///-------------------------------

/**
 Attempts to register a subclass of `AFHTTPRequestOperation`, adding it to a chain to automatically generate request operations from a URL request.
 
 @param The subclass of `AFHTTPRequestOperation` to register
 
 @return `YES` if the registration is successful, `NO` otherwise. The only failure condition is if `operationClass` does is not a subclass of `AFHTTPRequestOperation`.
 
 @discussion When `enqueueHTTPRequestOperationWithRequest:success:failure` is invoked, each registered class is consulted in turn to see if it can handle the specific request. The first class to return `YES` when sent a `canProcessRequest:` message is used to create an operation using `initWithURLRequest:` and do `setCompletionBlockWithSuccess:failure:`. There is no guarantee that all registered classes will be consulted. Classes are consulted in the reverse order of their registration. Attempting to register an already-registered class will move it to the top of the list.
 
 @see `AFHTTPClientOperation`
 */
- (BOOL)registerHTTPOperationClass:(Class)operationClass;

/**
 Unregisters the specified subclass of `AFHTTPRequestOperation`.
 
 @param The class conforming to the `AFHTTPClientOperation` protocol to unregister
 
 @discussion After this method is invoked, `operationClass` is no longer consulted when `requestWithMethod:path:parameters` is invoked.
 */
- (void)unregisterHTTPOperationClass:(Class)operationClass;

///----------------------------------
/// @name Managing HTTP Header Values
///----------------------------------

/**
 Returns the value for the HTTP headers set in request objects created by the HTTP client.
 
 @param header The HTTP header to return the default value for
 
 @return The default value for the HTTP header, or `nil` if unspecified
 */
- (NSString *)defaultValueForHeader:(NSString *)header;

/**
 Sets the value for the HTTP headers set in request objects made by the HTTP client. If `nil`, removes the existing value for that header.
 
 @param header The HTTP header to set a default value for
 @param value The value set as default for the specified header, or `nil
 */
- (void)setDefaultHeader:(NSString *)header value:(NSString *)value;

/**
 Sets the "Authorization" HTTP header set in request objects made by the HTTP client to a basic authentication value with Base64-encoded username and password. This overwrites any existing value for this header.
 
 @param username The HTTP basic auth username
 @param password The HTTP basic auth password
 */
- (void)setAuthorizationHeaderWithUsername:(NSString *)username password:(NSString *)password;

/**
 Sets the "Authorization" HTTP header set in request objects made by the HTTP client to a token-based authentication value, such as an OAuth access token. This overwrites any existing value for this header.
 
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
 Creates an `NSMutableURLRequest` object with the specified HTTP method and path.
 
 If the HTTP method is `GET`, the parameters will be used to construct a url-encoded query string that is appended to the request's URL. Otherwise, the parameters will be encoded according to the value of the `parameterEncoding` property, and set as the request body.
 
 @param method The HTTP method for the request, such as `GET`, `POST`, `PUT`, or `DELETE`.
 @param path The path to be appended to the HTTP client's base URL and used as the request URL.
 @param parameters The parameters to be either set as a query string for `GET` requests, or the request HTTP body.
  
 @return An `NSMutableURLRequest` object 
 */
- (NSMutableURLRequest *)requestWithMethod:(NSString *)method 
                                      path:(NSString *)path 
                                parameters:(NSDictionary *)parameters;

/**
 Creates an `NSMutableURLRequest` object with the specified HTTP method and path, and constructs a `multipart/form-data` HTTP body, using the specified parameters and multipart form data block. See http://www.w3.org/TR/html4/interact/forms.html#h-17.13.4.2
 
 @param method The HTTP method for the request. Must be either `POST`, `PUT`, or `DELETE`.
 @param path The path to be appended to the HTTP client's base URL and used as the request URL.
 @param parameters The parameters to be encoded and set in the request HTTP body.
 @param block A block that takes a single argument and appends data to the HTTP body. The block argument is an object adopting the `AFMultipartFormData` protocol. This can be used to upload files, encode HTTP body as JSON or XML, or specify multiple values for the same parameter, as one might for array values.
  
 @discussion The multipart form data is constructed synchronously in the specified block, so in cases where large amounts of data are being added to the request, you should consider performing this method in the background. Likewise, the form data is constructed in-memory, so it may be advantageous to instead write parts of the form data to a file and stream the request body using the `HTTPBodyStream` property of `NSURLRequest`.
 
 @warning An exception will be raised if the specified method is not `POST`, `PUT` or `DELETE`.
 
 @return An `NSMutableURLRequest` object
 */
- (NSMutableURLRequest *)multipartFormRequestWithMethod:(NSString *)method
                                                   path:(NSString *)path
                                             parameters:(NSDictionary *)parameters
                              constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block;

///-------------------------------
/// @name Creating HTTP Operations
///-------------------------------

/**
 Creates an `AFHTTPRequestOperation`.
 
 In order to determine what kind of operation is created, each registered subclass conforming to the `AFHTTPClient` protocol is consulted (in reverse order of when they were specified) to see if it can handle the specific request. The first class to return `YES` when sent a `canProcessRequest:` message is used to generate an operation using `HTTPRequestOperationWithRequest:success:failure:`.
 
 @param request The request object to be loaded asynchronously during execution of the operation.
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes two arguments: the created request operation and the object created from the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the resonse data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.
 */
- (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)request 
                                                    success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                                    failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

///----------------------------------------
/// @name Managing Enqueued HTTP Operations
///----------------------------------------

/**
 Enqueues an `AFHTTPRequestOperation` to the HTTP client's operation queue.
 
 @param operation The HTTP request operation to be enqueued.
 */
- (void)enqueueHTTPRequestOperation:(AFHTTPRequestOperation *)operation;

/**
 Cancels all operations in the HTTP client's operation queue whose URLs match the specified HTTP method and path.
 
 @param method The HTTP method to match for the cancelled requests, such as `GET`, `POST`, `PUT`, or `DELETE`. If `nil`, all request operations with URLs matching the path will be cancelled. 
 @param url The path to match for the cancelled requests.
 */
- (void)cancelAllHTTPOperationsWithMethod:(NSString *)method path:(NSString *)path;

///---------------------------------------
/// @name Batching HTTP Request Operations
///---------------------------------------

/**
 Creates and enqueues an `AFHTTPRequestOperation` to the HTTP client's operation queue for each specified request object into a batch. When each request operation finishes, the specified progress block is executed, until all of the request operations have finished, at which point the completion block also executes.
 
 @param requests The `NSURLRequest` objects used to create and enqueue operations.
 @param progressBlock A block object to be executed upon the completion of each request operation in the batch. This block has no return value and takes two arguments: the number of operations that have already finished execution, and the total number of operations.
 @param completionBlock A block object to be executed upon the completion of all of the request operations in the batch. This block has no return value and takes a single argument: the batched request operations. 
 
 @discussion Operations are created by passing the specified `NSURLRequest` objects in `requests`, using `-HTTPRequestOperationWithRequest:success:failure:`, with `nil` for both the `success` and `failure` parameters.
 */
- (void)enqueueBatchOfHTTPRequestOperationsWithRequests:(NSArray *)requests 
                                          progressBlock:(void (^)(NSUInteger numberOfCompletedOperations, NSUInteger totalNumberOfOperations))progressBlock 
                                        completionBlock:(void (^)(NSArray *operations))completionBlock;

/**
 Enqueues the specified request operations into a batch. When each request operation finishes, the specified progress block is executed, until all of the request operations have finished, at which point the completion block also executes.
 
 @param operations The request operations used to be batched and enqueued.
 @param progressBlock A block object to be executed upon the completion of each request operation in the batch. This block has no return value and takes two arguments: the number of operations that have already finished execution, and the total number of operations.
 @param completionBlock A block object to be executed upon the completion of all of the request operations in the batch. This block has no return value and takes a single argument: the batched request operations. 
 */
- (void)enqueueBatchOfHTTPRequestOperations:(NSArray *)operations 
                              progressBlock:(void (^)(NSUInteger numberOfCompletedOperations, NSUInteger totalNumberOfOperations))progressBlock 
                            completionBlock:(void (^)(NSArray *operations))completionBlock;

///---------------------------
/// @name Making HTTP Requests
///---------------------------

/**
 Creates an `AFHTTPRequestOperation` with a `GET` request, and enqueues it to the HTTP client's operation queue.
 
 @param path The path to be appended to the HTTP client's base URL and used as the request URL.
 @param parameters The parameters to be encoded and appended as the query string for the request URL.
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes two arguments: the created request operation and the object created from the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the resonse data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.
 
 @see HTTPRequestOperationWithRequest:success:failure
 */
- (void)getPath:(NSString *)path
     parameters:(NSDictionary *)parameters
        success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
        failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**
 Creates an `AFHTTPRequestOperation` with a `POST` request, and enqueues it to the HTTP client's operation queue.
 
 @param path The path to be appended to the HTTP client's base URL and used as the request URL.
 @param parameters The parameters to be encoded and set in the request HTTP body.
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes two arguments: the created request operation and the object created from the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the resonse data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.
 
 @see HTTPRequestOperationWithRequest:success:failure
 */
- (void)postPath:(NSString *)path 
      parameters:(NSDictionary *)parameters 
         success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**
 Creates an `AFHTTPRequestOperation` with a `PUT` request, and enqueues it to the HTTP client's operation queue.
 
 @param path The path to be appended to the HTTP client's base URL and used as the request URL.
 @param parameters The parameters to be encoded and set in the request HTTP body.
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes two arguments: the created request operation and the object created from the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the resonse data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.
 
 @see HTTPRequestOperationWithRequest:success:failure
 */
- (void)putPath:(NSString *)path 
     parameters:(NSDictionary *)parameters 
        success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
        failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**
 Creates an `AFHTTPRequestOperation` with a `DELETE` request, and enqueues it to the HTTP client's operation queue.
 
 @param path The path to be appended to the HTTP client's base URL and used as the request URL.
 @param parameters The parameters to be encoded and set in the request HTTP body.
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes two arguments: the created request operation and the object created from the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the resonse data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.
 
 @see HTTPRequestOperationWithRequest:success:failure
 */
- (void)deletePath:(NSString *)path 
        parameters:(NSDictionary *)parameters 
           success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
           failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**
 Creates an `AFHTTPRequestOperation` with a `PATCH` request, and enqueues it to the HTTP client's operation queue.
 
 @param path The path to be appended to the HTTP client's base URL and used as the request URL.
 @param parameters The parameters to be encoded and set in the request HTTP body.
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes two arguments: the created request operation and the object created from the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the resonse data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.
 
 @see HTTPRequestOperationWithRequest:success:failure
 */
- (void)patchPath:(NSString *)path
       parameters:(NSDictionary *)parameters 
          success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
          failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
@end

#pragma mark -

/**
 The `AFMultipartFormData` protocol defines the methods supported by the parameter in the block argument of `multipartFormRequestWithMethod:path:parameters:constructingBodyWithBlock:`.
 
 @see `AFHTTPClient -multipartFormRequestWithMethod:path:parameters:constructingBodyWithBlock:`
 */
@protocol AFMultipartFormData

/**
 Appends HTTP headers, followed by the encoded data and the multipart form boundary.
 
 @param headers The HTTP headers to be appended to the form data.
 @param body The data to be encoded and appended to the form data.
 */
- (void)appendPartWithHeaders:(NSDictionary *)headers body:(NSData *)body;

/**
 Appends the HTTP headers `Content-Disposition: form-data; name=#{name}"`, followed by the encoded data and the multipart form boundary.
 
 @param data The data to be encoded and appended to the form data.
 @param name The name to be associated with the specified data. This parameter must not be `nil`.
 */
- (void)appendPartWithFormData:(NSData *)data name:(NSString *)name;

/**
 Appends the HTTP header `Content-Disposition: file; filename=#{filename}; name=#{name}"` and `Content-Type: #{mimeType}`, followed by the encoded file data and the multipart form boundary.
 
 @param data The data to be encoded and appended to the form data.
 @param name The name to be associated with the specified data. This parameter must not be `nil`.
 @param mimeType The MIME type of the specified data. (For example, the MIME type for a JPEG image is image/jpeg.) For a list of valid MIME types, see http://www.iana.org/assignments/media-types/. This parameter must not be `nil`.
 @param filename The filename to be associated with the specified data. This parameter must not be `nil`.
 */
- (void)appendPartWithFileData:(NSData *)data name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType;

/**
 Appends the HTTP header `Content-Disposition: file; filename=#{generated filename}; name=#{name}"` and `Content-Type: #{generated mimeType}`, followed by the encoded file data and the multipart form boundary.
 
 @param fileURL The URL corresponding to the file whose content will be appended to the form.
 @param name The name to be associated with the specified data. This parameter must not be `nil`.
 @param error If an error occurs, upon return contains an `NSError` object that describes the problem.
 
 @return `YES` if the file data was successfully appended, otherwise `NO`.
 
 @discussion The filename and MIME type for this data in the form will be automatically generated, using `NSURLResponse` `-suggestedFilename` and `-MIMEType`, respectively.
 */
- (BOOL)appendPartWithFileURL:(NSURL *)fileURL name:(NSString *)name error:(NSError **)error;

/**
 Appends encoded data to the form data.
 
 @param data The data to be encoded and appended to the form data.
 */
- (void)appendData:(NSData *)data;

/**
 Appends a string to the form data.
 
 @param string The string to be encoded and appended to the form data.
 */
- (void)appendString:(NSString *)string;

@end

