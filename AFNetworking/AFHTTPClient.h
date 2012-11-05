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

/**
 `AFHTTPClient` captures the common patterns of communicating with an web application over HTTP. It encapsulates information like base URL, authorization credentials, and HTTP headers, and uses them to construct and manage the execution of HTTP request operations.
 
 ## Automatic Content Parsing
 
 Instances of `AFHTTPClient` may specify which types of requests it expects and should handle by registering HTTP operation classes for automatic parsing. Registered classes will determine whether they can handle a particular request, and then construct a request operation accordingly in `enqueueHTTPRequestOperationWithRequest:success:failure`.
 
 ## Subclassing Notes
 
 In most cases, one should create an `AFHTTPClient` subclass for each website or web application that your application communicates with. It is often useful, also, to define a class method that returns a singleton shared HTTP client in each subclass, that persists authentication credentials and other configuration across the entire application.
 
 ## Methods to Override
 
 To change the behavior of all url request construction for an `AFHTTPClient` subclass, override `requestWithMethod:path:parameters`.
 
 To change the behavior of all request operation construction for an `AFHTTPClient` subclass, override `HTTPRequestOperationWithRequest:success:failure`.
 
 ## Default Headers
 
 By default, `AFHTTPClient` sets the following HTTP headers:
 
 - `Accept-Encoding: gzip`
 - `Accept-Language: (comma-delimited preferred languages), en-us;q=0.8`
 - `User-Agent: (generated user agent)`
 
 You can override these HTTP headers or define new ones using `setDefaultHeader:value:`.
 
 ## URL Construction Using Relative Paths
 
 Both `-requestWithMethod:path:parameters:` and `-multipartFormRequestWithMethod:path:parameters:constructingBodyWithBlock:` construct URLs from the path relative to the `-baseURL`, using `NSURL +URLWithString:relativeToURL:`. Below are a few examples of how `baseURL` and relative paths interact:
 
    NSURL *baseURL = [NSURL URLWithString:@"http://example.com/v1/"];  
    [NSURL URLWithString:@"foo" relativeToURL:baseURL];                  // http://example.com/v1/foo
    [NSURL URLWithString:@"foo?bar=baz" relativeToURL:baseURL];          // http://example.com/v1/foo?bar=baz
    [NSURL URLWithString:@"/foo" relativeToURL:baseURL];                 // http://example.com/foo
    [NSURL URLWithString:@"foo/" relativeToURL:baseURL];                 // http://example.com/v1/foo
    [NSURL URLWithString:@"/foo/" relativeToURL:baseURL];                // http://example.com/foo/
    [NSURL URLWithString:@"http://example2.com/" relativeToURL:baseURL]; // http://example2.com/

 Also important to note is that a trailing slash will be added to any `baseURL` without one, which would otherwise cause unexpected behavior when constructing URLs using paths without a leading slash.

 ## NSCoding / NSCopying Conformance
 
 `AFHTTPClient`  conforms to the `NSCoding` and `NSCopying` protocols, allowing operations to be archived to disk, and copied in memory, respectively. There are a few minor caveats to keep in mind, however:
 
 - Archives and copies of HTTP clients will be initialized with an empty operation queue.
 - NSCoding cannot serialize / deserialize block properties, so an archive of an HTTP client will not include any reachability callback block that may be set.
 */

#ifdef _SYSTEMCONFIGURATION_H
typedef enum {
    AFNetworkReachabilityStatusUnknown          = -1,
    AFNetworkReachabilityStatusNotReachable     = 0,
    AFNetworkReachabilityStatusReachableViaWWAN = 1,
    AFNetworkReachabilityStatusReachableViaWiFi = 2,
} AFNetworkReachabilityStatus;
#else
#warning "SystemConfiguration framework not found in project, or not included in precompiled header. Network reachability functionality will not be available."
#endif

#ifndef __UTTYPE__
#warning "CoreServices framework not found in project, or not included in precompiled header. Automatic MIME type detection when uploading files in multipart requests will not be available."
#endif

typedef enum {
    AFFormURLParameterEncoding,
    AFJSONParameterEncoding,
    AFPropertyListParameterEncoding,
} AFHTTPClientParameterEncoding;

@class AFHTTPRequestOperation;
@protocol AFMultipartFormData;

@interface AFHTTPClient : NSObject <NSCoding, NSCopying>

///---------------------------------------
/// @name Accessing HTTP Client Properties
///---------------------------------------

/**
 The url used as the base for paths specified in methods such as `getPath:parameters:success:failure`
 */
@property (readonly, nonatomic) NSURL *baseURL;

/**
 The string encoding used in constructing url requests. This is `NSUTF8StringEncoding` by default.
 */
@property (nonatomic, assign) NSStringEncoding stringEncoding;

/**
 The `AFHTTPClientParameterEncoding` value corresponding to how parameters are encoded into a request body. This is `AFFormURLParameterEncoding` by default.
 
 @warning Some nested parameter structures, such as a keyed array of hashes containing inconsistent keys (i.e. `@{@"": @[@{@"a" : @(1)}, @{@"b" : @(2)}]}`), cannot be unambiguously represented in query strings. It is strongly recommended that an unambiguous encoding, such as `AFJSONParameterEncoding`, is used when posting complicated or nondeterministic parameter structures.
 */
@property (nonatomic, assign) AFHTTPClientParameterEncoding parameterEncoding;

/**
 The operation queue which manages operations enqueued by the HTTP client.
 */
@property (readonly, nonatomic) NSOperationQueue *operationQueue;

/**
 The reachability status from the device to the current `baseURL` of the `AFHTTPClient`.

  @warning This property requires the `SystemConfiguration` framework. Add it in the active target's "Link Binary With Library" build phase, and add `#import <SystemConfiguration/SystemConfiguration.h>` to the header prefix of the project (`Prefix.pch`).
 */
#ifdef _SYSTEMCONFIGURATION_H
@property (readonly, nonatomic, assign) AFNetworkReachabilityStatus networkReachabilityStatus;
#endif

///---------------------------------------------
/// @name Creating and Initializing HTTP Clients
///---------------------------------------------

/**
 Creates and initializes an `AFHTTPClient` object with the specified base URL.
 
 @param url The base URL for the HTTP client. This argument must not be `nil`.
  
 @return The newly-initialized HTTP client
 */
+ (AFHTTPClient *)clientWithBaseURL:(NSURL *)url;

/**
 Initializes an `AFHTTPClient` object with the specified base URL.
 
 @param url The base URL for the HTTP client. This argument must not be `nil`.
 
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
 
 @warning This method requires the `SystemConfiguration` framework. Add it in the active target's "Link Binary With Library" build phase, and add `#import <SystemConfiguration/SystemConfiguration.h>` to the header prefix of the project (`Prefix.pch`).
 */
#ifdef _SYSTEMCONFIGURATION_H
- (void)setReachabilityStatusChangeBlock:(void (^)(AFNetworkReachabilityStatus status))block;
#endif

///-------------------------------
/// @name Managing HTTP Operations
///-------------------------------

/**
 Attempts to register a subclass of `AFHTTPRequestOperation`, adding it to a chain to automatically generate request operations from a URL request.
 
 @param operationClass The subclass of `AFHTTPRequestOperation` to register
 
 @return `YES` if the registration is successful, `NO` otherwise. The only failure condition is if `operationClass` is not a subclass of `AFHTTPRequestOperation`.
 
 @discussion When `enqueueHTTPRequestOperationWithRequest:success:failure` is invoked, each registered class is consulted in turn to see if it can handle the specific request. The first class to return `YES` when sent a `canProcessRequest:` message is used to create an operation using `initWithURLRequest:` and do `setCompletionBlockWithSuccess:failure:`. There is no guarantee that all registered classes will be consulted. Classes are consulted in the reverse order of their registration. Attempting to register an already-registered class will move it to the top of the list.
 */
- (BOOL)registerHTTPOperationClass:(Class)operationClass;

/**
 Unregisters the specified subclass of `AFHTTPRequestOperation` from the chain of classes consulted when `-requestWithMethod:path:parameters` is called.

 @param operationClass The subclass of `AFHTTPRequestOperation` to register 
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
 
 If the HTTP method is `GET`, `HEAD`, or `DELETE`, the parameters will be used to construct a url-encoded query string that is appended to the request's URL. Otherwise, the parameters will be encoded according to the value of the `parameterEncoding` property, and set as the request body.
 
 @param method The HTTP method for the request, such as `GET`, `POST`, `PUT`, or `DELETE`. This parameter must not be `nil`.
 @param path The path to be appended to the HTTP client's base URL and used as the request URL. If `nil`, no path will be appended to the base URL.
 @param parameters The parameters to be either set as a query string for `GET` requests, or the request HTTP body.
  
 @return An `NSMutableURLRequest` object 
 */
- (NSMutableURLRequest *)requestWithMethod:(NSString *)method 
                                      path:(NSString *)path 
                                parameters:(NSDictionary *)parameters;

/**
 Creates an `NSMutableURLRequest` object with the specified HTTP method and path, and constructs a `multipart/form-data` HTTP body, using the specified parameters and multipart form data block. See http://www.w3.org/TR/html4/interact/forms.html#h-17.13.4.2
 
 @param method The HTTP method for the request. This parameter must not be `GET` or `HEAD`, or `nil`.
 @param path The path to be appended to the HTTP client's base URL and used as the request URL.
 @param parameters The parameters to be encoded and set in the request HTTP body.
 @param block A block that takes a single argument and appends data to the HTTP body. The block argument is an object adopting the `AFMultipartFormData` protocol. This can be used to upload files, encode HTTP body as JSON or XML, or specify multiple values for the same parameter, as one might for array values.
  
 @discussion Multipart form requests are automatically streamed, reading files directly from disk along with in-memory data in a single HTTP body. The resulting `NSMutableURLRequest` object has an `HTTPBodyStream` property, so refrain from setting `HTTPBodyStream` or `HTTPBody` on this request object, as it will clear out the multipart form body stream.
  
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
 
 @param urlRequest The request object to be loaded asynchronously during execution of the operation.
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes two arguments: the created request operation and the object created from the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.
 */
- (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)urlRequest
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
 @param path The path appended to the HTTP client base URL to match against the cancelled requests. If `nil`, no path will be appended to the base URL.
 
 @discussion This method only cancels `AFHTTPRequestOperations` whose request URL matches the HTTP client base URL with the path appended. For complete control over the lifecycle of enqueued operations, you can access the `operationQueue` property directly, which allows you to, for instance, cancel operations filtered by a predicate, or simply use `-cancelAllRequests`. Note that the operation queue may include non-HTTP operations, so be sure to check the type before attempting to directly introspect an operation's `request` property.
 */
- (void)cancelAllHTTPOperationsWithMethod:(NSString *)method path:(NSString *)path;

///---------------------------------------
/// @name Batching HTTP Request Operations
///---------------------------------------

/**
 Creates and enqueues an `AFHTTPRequestOperation` to the HTTP client's operation queue for each specified request object into a batch. When each request operation finishes, the specified progress block is executed, until all of the request operations have finished, at which point the completion block also executes.
 
 @param urlRequests The `NSURLRequest` objects used to create and enqueue operations.
 @param progressBlock A block object to be executed upon the completion of each request operation in the batch. This block has no return value and takes two arguments: the number of operations that have already finished execution, and the total number of operations.
 @param completionBlock A block object to be executed upon the completion of all of the request operations in the batch. This block has no return value and takes a single argument: the batched request operations. 
 
 @discussion Operations are created by passing the specified `NSURLRequest` objects in `requests`, using `-HTTPRequestOperationWithRequest:success:failure:`, with `nil` for both the `success` and `failure` parameters.
 */
- (void)enqueueBatchOfHTTPRequestOperationsWithRequests:(NSArray *)urlRequests
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
 Creates an `AFHTTPRequestOperation` with a `GET` request, and enqueues it to the HTTP client's operation queue.
 
 @param path The path to be appended to the HTTP client's base URL and used as the request URL.
 @param parameters The parameters to be encoded and appended as the query string for the request URL.
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes two arguments: the created request operation and the object created from the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.
 
 @see -HTTPRequestOperationWithRequest:success:failure:
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
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.
 
 @see -HTTPRequestOperationWithRequest:success:failure:
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
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.
 
 @see -HTTPRequestOperationWithRequest:success:failure:
 */
- (void)putPath:(NSString *)path 
     parameters:(NSDictionary *)parameters 
        success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
        failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**
 Creates an `AFHTTPRequestOperation` with a `DELETE` request, and enqueues it to the HTTP client's operation queue.
 
 @param path The path to be appended to the HTTP client's base URL and used as the request URL.
 @param parameters The parameters to be encoded and appended as the query string for the request URL.
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes two arguments: the created request operation and the object created from the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.
 
 @see -HTTPRequestOperationWithRequest:success:failure:
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
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.
 
 @see -HTTPRequestOperationWithRequest:success:failure:
 */
- (void)patchPath:(NSString *)path
       parameters:(NSDictionary *)parameters 
          success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
          failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
@end

///----------------
/// @name Constants
///----------------

/**
 ### Network Reachability
 
 The following constants are provided by `AFHTTPClient` as possible network reachability statuses. 
 
 enum {
    AFNetworkReachabilityStatusUnknown,
    AFNetworkReachabilityStatusNotReachable,
    AFNetworkReachabilityStatusReachableViaWWAN,
    AFNetworkReachabilityStatusReachableViaWiFi,
 }
 
 `AFNetworkReachabilityStatusUnknown`  
    The `baseURL` host reachability is not known.
 
 `AFNetworkReachabilityStatusNotReachable`
    The `baseURL` host cannot be reached.
 
 `AFNetworkReachabilityStatusReachableViaWWAN`
    The `baseURL` host can be reached via a cellular connection, such as EDGE or GPRS.
 
 `AFNetworkReachabilityStatusReachableViaWiFi`
    The `baseURL` host can be reached via a Wi-Fi connection.
 
 ### Keys for Notification UserInfo Dictionary
 
 Strings that are used as keys in a `userInfo` dictionary in a network reachability status change notification.
 
 `AFNetworkingReachabilityNotificationStatusItem`
    A key in the userInfo dictionary in a `AFNetworkingReachabilityDidChangeNotification` notification.  
    The corresponding value is an `NSNumber` object representing the `AFNetworkReachabilityStatus` value for the current reachability status. 
 
 ### Parameter Encoding
 
 The following constants are provided by `AFHTTPClient` as possible methods for serializing parameters into query string or message body values.

 enum {
    AFFormURLParameterEncoding,
    AFJSONParameterEncoding,
    AFPropertyListParameterEncoding,
 }
 
 `AFFormURLParameterEncoding`
    Parameters are encoded into field/key pairs in the URL query string for `GET` `HEAD` and `DELETE` requests, and in the message body otherwise. Dictionary keys are sorted with the `caseInsensitiveCompare:` selector of their description, in order to mitigate the possibility of ambiguous query strings being generated non-deterministically. See the warning for the `parameterEncoding` property for additional information.
 
 `AFJSONParameterEncoding`
    Parameters are encoded into JSON in the message body.
 
 `AFPropertyListParameterEncoding`  
    Parameters are encoded into a property list in the message body.
 */

///----------------
/// @name Functions
///----------------

/**
 Returns a query string constructed by a set of parameters, using the specified encoding.
 
 @param parameters The parameters used to construct the query string
 @param encoding The encoding to use in constructing the query string. If you are uncertain of the correct encoding, you should use UTF-8 (`NSUTF8StringEncoding`), which is the encoding designated by RFC 3986 as the correct encoding for use in URLs.
 
 @discussion Query strings are constructed by collecting each key-value pair, percent escaping a string representation of the key-value pair, and then joining the pairs with "&".
 
 If a query string pair has a an `NSArray` for its value, each member of the array will be represented in the format `field[]=value1&field[]value2`. Otherwise, the pair will be formatted as "field=value". String representations of both keys and values are derived using the `-description` method. The constructed query string does not include the ? character used to delimit the query component.
 
 @return A percent-escaped query string
 */
extern NSString * AFQueryStringFromParametersWithEncoding(NSDictionary *parameters, NSStringEncoding encoding);

///--------------------
/// @name Notifications
///--------------------

/**
 Posted when network reachability changes.
 This notification assigns no notification object. The `userInfo` dictionary contains an `NSNumber` object under the `AFNetworkingReachabilityNotificationStatusItem` key, representing the `AFNetworkReachabilityStatus` value for the current network reachability.
 
 @warning In order for network reachability to be monitored, include the `SystemConfiguration` framework in the active target's "Link Binary With Library" build phase, and add `#import <SystemConfiguration/SystemConfiguration.h>` to the header prefix of the project (`Prefix.pch`).
 */
#ifdef _SYSTEMCONFIGURATION_H
extern NSString * const AFNetworkingReachabilityDidChangeNotification;
extern NSString * const AFNetworkingReachabilityNotificationStatusItem;
#endif

#pragma mark -

extern NSUInteger const kAFUploadStream3GSuggestedPacketSize;
extern NSTimeInterval const kAFUploadStream3GSuggestedDelay;

/**
 The `AFMultipartFormData` protocol defines the methods supported by the parameter in the block argument of `AFHTTPClient -multipartFormRequestWithMethod:path:parameters:constructingBodyWithBlock:`.
 */
@protocol AFMultipartFormData

/**
 Appends the HTTP header `Content-Disposition: file; filename=#{generated filename}; name=#{name}"` and `Content-Type: #{generated mimeType}`, followed by the encoded file data and the multipart form boundary.
 
 @param fileURL The URL corresponding to the file whose content will be appended to the form. This parameter must not be `nil`.
 @param name The name to be associated with the specified data. This parameter must not be `nil`.
 @param error If an error occurs, upon return contains an `NSError` object that describes the problem.
 
 @return `YES` if the file data was successfully appended, otherwise `NO`.
 
 @discussion The filename and MIME type for this data in the form will be automatically generated, using `NSURLResponse` `-suggestedFilename` and `-MIMEType`, respectively.
 */
- (BOOL)appendPartWithFileURL:(NSURL *)fileURL
                         name:(NSString *)name
                        error:(NSError * __autoreleasing *)error;

/**
 Appends the HTTP header `Content-Disposition: file; filename=#{filename}; name=#{name}"` and `Content-Type: #{mimeType}`, followed by the encoded file data and the multipart form boundary.
 
 @param data The data to be encoded and appended to the form data.
 @param name The name to be associated with the specified data. This parameter must not be `nil`.
 @param filename The filename to be associated with the specified data. This parameter must not be `nil`.
 @param mimeType The MIME type of the specified data. (For example, the MIME type for a JPEG image is image/jpeg.) For a list of valid MIME types, see http://www.iana.org/assignments/media-types/. This parameter must not be `nil`.
 */
- (void)appendPartWithFileData:(NSData *)data
                          name:(NSString *)name
                      fileName:(NSString *)fileName
                      mimeType:(NSString *)mimeType;

/**
 Appends the HTTP headers `Content-Disposition: form-data; name=#{name}"`, followed by the encoded data and the multipart form boundary.
 
 @param data The data to be encoded and appended to the form data.
 @param name The name to be associated with the specified data. This parameter must not be `nil`.
 */

- (void)appendPartWithFormData:(NSData *)data
                          name:(NSString *)name;

/**
 Appends HTTP headers, followed by the encoded data and the multipart form boundary.
 
 @param headers The HTTP headers to be appended to the form data.
 @param body The data to be encoded and appended to the form data.
 */
- (void)appendPartWithHeaders:(NSDictionary *)headers
                         body:(NSData *)body;

/**
 Throttles request bandwidth by limiting the packet size and adding a delay for each chunk read from the upload stream.
 
 @param numberOfBytes Maximum packet size, in number of bytes. The default packet size for an input stream is 32kb.
 @param delay Duration of delay each time a packet is read. By default, no delay is set.
 
 @discussion When uploading over a 3G or EDGE connection, requests may fail with "request body stream exhausted". Setting a maximum packet size and delay according to the recommended values (`kAFUploadStream3GSuggestedPacketSize` and `kAFUploadStream3GSuggestedDelay`) lowers the risk of the input stream exceeding its allocated bandwidth. Unfortunately, as of iOS 6, there is no definite way to distinguish between a 3G, EDGE, or LTE connection. As such, it is not recommended that you throttle bandwidth based solely on network reachability. Instead, you should consider checking for the "request body stream exhausted" in a failure block, and then retrying the request with throttled bandwidth.
 */
- (void)throttleBandwidthWithPacketSize:(NSUInteger)numberOfBytes
                                  delay:(NSTimeInterval)delay;

@end
