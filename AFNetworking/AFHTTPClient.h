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
#import "AFSerialization.h"

/**
 `AFHTTPClient` encapsulates the common patterns of communicating with an web application over HTTP, including request creation, response serialization, network reachability monitoring, and security, as well as both request operation and session task management.

 ## Subclassing Notes

 In most cases, one should create an `AFHTTPClient` subclass for each website or web application that your application communicates with. It is often useful, also, to define a class method that returns a singleton shared HTTP client in each subclass, that persists authentication credentials and other configuration across the entire application.

 ## Methods to Override

 To change the behavior of all url request construction for an `AFHTTPClient` subclass, override `requestWithMethod:path:parameters`.

 To change the behavior of all request operation construction for an `AFHTTPClient` subclass, override `HTTPRequestOperationWithRequest:success:failure`.

 ## Default Headers

 By default, `AFHTTPClient` sets the following HTTP headers:

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

typedef NS_ENUM(NSInteger, AFNetworkReachabilityStatus) {
    AFNetworkReachabilityStatusUnknown          = -1,
    AFNetworkReachabilityStatusNotReachable     = 0,
    AFNetworkReachabilityStatusReachableViaWWAN = 1,
    AFNetworkReachabilityStatusReachableViaWiFi = 2,
};

@protocol AFMultipartFormData;
@interface AFHTTPClient : AFURLSessionManager <NSCoding, NSCopying>

///---------------------------------------
/// @name Accessing HTTP Client Properties
///---------------------------------------

/**
 The url used as the base for paths specified in methods such as `getPath:parameters:success:failure`
 */
@property (readonly, nonatomic, strong) NSURL *baseURL;

/**

 */
@property (nonatomic, strong) id <AFURLRequestSerialization> requestSerializer;

/**

 */
@property (nonatomic, strong) NSArray *responseSerializers;

/**
 The reachability status from the device to the current `baseURL` of the `AFHTTPClient`.
 */
@property (readonly, nonatomic, assign) AFNetworkReachabilityStatus networkReachabilityStatus;

/**
 Default SSL pinning mode for each `AFHTTPRequestOperation` created by `HTTPRequestOperationWithRequest:success:failure:`.
 */
@property (nonatomic, assign) AFURLConnectionOperationSSLPinningMode SSLPinningMode;

/**
 Whether each `AFHTTPRequestOperation` created by `HTTPRequestOperationWithRequest:success:failure:` should accept an invalid SSL certificate.

 If `_AFNETWORKING_ALLOW_INVALID_SSL_CERTIFICATES_` is set, this property defaults to `YES` for backwards compatibility. Otherwise, this property defaults to `NO`.
 */
@property (nonatomic, assign) BOOL allowsInvalidSSLCertificate;

///---------------------------------------------
/// @name Creating and Initializing HTTP Clients
///---------------------------------------------

/**
 
 */
+ (instancetype)client;

/**
 Initializes an `AFHTTPClient` object with the specified base URL.
 
 This is the designated initializer.

 @param url The base URL for the HTTP client. This argument must not be `nil`.

 @return The newly-initialized HTTP client
 */
- (instancetype)initWithBaseURL:(NSURL *)url;

/**
 
 */
- (instancetype)initWithBaseURL:(NSURL *)url
           sessionConfiguration:(NSURLSessionConfiguration *)configuration;

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

 Multipart form requests are automatically streamed, reading files directly from disk along with in-memory data in a single HTTP body. The resulting `NSMutableURLRequest` object has an `HTTPBodyStream` property, so refrain from setting `HTTPBodyStream` or `HTTPBody` on this request object, as it will clear out the multipart form body stream.
 
 @param method The HTTP method for the request. This parameter must not be `GET` or `HEAD`, or `nil`.
 @param path The path to be appended to the HTTP client's base URL and used as the request URL.
 @param parameters The parameters to be encoded and set in the request HTTP body.
 @param block A block that takes a single argument and appends data to the HTTP body. The block argument is an object adopting the `AFMultipartFormData` protocol. 
 
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

 @param urlRequest The request object to be loaded asynchronously during execution of the operation.
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes two arguments: the created request operation and the object created from the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.
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

 This method only cancels `AFHTTPRequestOperations` whose request URL matches the HTTP client base URL with the path appended. For complete control over the lifecycle of enqueued operations, you can access the `operationQueue` property directly, which allows you to, for instance, cancel operations filtered by a predicate, or simply use `-cancelAllRequests`. Note that the operation queue may include non-HTTP operations, so be sure to check the type before attempting to directly introspect an operation's `request` property.

 @param method The HTTP method to match for the cancelled requests, such as `GET`, `POST`, `PUT`, or `DELETE`. If `nil`, all request operations with URLs matching the path will be cancelled.
 @param path The path appended to the HTTP client base URL to match against the cancelled requests. If `nil`, no path will be appended to the base URL.
 */
- (void)cancelAllHTTPOperationsWithMethod:(NSString *)method
                                     path:(NSString *)path;

///---------------------------------------
/// @name Batching HTTP Request Operations
///---------------------------------------

/**
 Creates and enqueues an `AFHTTPRequestOperation` to the HTTP client's operation queue for each specified request object into a batch. When each request operation finishes, the specified progress block is executed, until all of the request operations have finished, at which point the completion block also executes.

 Operations are created by passing the specified `NSURLRequest` objects in `requests`, using `-HTTPRequestOperationWithRequest:success:failure:`, with `nil` for both the `success` and `failure` parameters.

 @param urlRequests The `NSURLRequest` objects used to create and enqueue operations.
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

 @param path The path to be appended to the HTTP client's base URL and used as the request URL.
 @param parameters The parameters to be encoded according to the client request serializer.
 @param success A block object to be executed when the task finishes successfully. This block has no return value and takes two arguments: the server response, and the response object created by the client response serializer.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes a single arguments: the error describing the network or parsing error that occurred.

 @see -runDataTaskWithRequest:success:failure:
 */
- (NSURLSessionDataTask *)GET:(NSString *)URLString
                   parameters:(NSDictionary *)parameters
                      success:(void (^)(NSHTTPURLResponse *response, id responseObject))success
                      failure:(void (^)(NSError *error))failure;

/**
 Creates and runs an `NSURLSessionDataTask` with a `HEAD` request.

 @param path The path to be appended to the HTTP client's base URL and used as the request URL.
 @param parameters The parameters to be encoded according to the client request serializer.
 @param success A block object to be executed when the task finishes successfully. This block has no return value and takes a single arguments: the server response.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes a single arguments: the error describing the network or parsing error that occurred.

 @see -runDataTaskWithRequest:success:failure:
 */
- (NSURLSessionDataTask *)HEAD:(NSString *)URLString
                    parameters:(NSDictionary *)parameters
                       success:(void (^)(NSHTTPURLResponse *response))success
                       failure:(void (^)(NSError *error))failure;

/**
 Creates and runs an `NSURLSessionDataTask` with a `POST` request.

 @param path The path to be appended to the HTTP client's base URL and used as the request URL.
 @param parameters The parameters to be encoded according to the client request serializer.
 @param success A block object to be executed when the task finishes successfully. This block has no return value and takes two arguments: the server response, and the response object created by the client response serializer.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes a single arguments: the error describing the network or parsing error that occurred.

 @see -runDataTaskWithRequest:success:failure:
 */
- (NSURLSessionDataTask *)POST:(NSString *)URLString
                    parameters:(NSDictionary *)parameters
                       success:(void (^)(NSHTTPURLResponse *response, id responseObject))success
                       failure:(void (^)(NSError *error))failure;

/**
 Creates and runs an `NSURLSessionDataTask` with a multipart `POST` request.

 @param path The path to be appended to the HTTP client's base URL and used as the request URL.
 @param parameters The parameters to be encoded according to the client request serializer.
 @param block A block that takes a single argument and appends data to the HTTP body. The block argument is an object adopting the `AFMultipartFormData` protocol.
 @param success A block object to be executed when the task finishes successfully. This block has no return value and takes two arguments: the server response, and the response object created by the client response serializer.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes a single arguments: the error describing the network or parsing error that occurred.

 @see -runDataTaskWithRequest:success:failure:
 */
- (NSURLSessionDataTask *)POST:(NSString *)URLString
                    parameters:(NSDictionary *)parameters
     constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
                       success:(void (^)(NSHTTPURLResponse *response, id responseObject))success
                       failure:(void (^)(NSError *error))failure;

/**
 Creates and runs an `NSURLSessionDataTask` with a `PUT` request.

 @param path The path to be appended to the HTTP client's base URL and used as the request URL.
 @param parameters The parameters to be encoded according to the client request serializer.
 @param success A block object to be executed when the task finishes successfully. This block has no return value and takes two arguments: the server response, and the response object created by the client response serializer.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes a single arguments: the error describing the network or parsing error that occurred.

 @see -runDataTaskWithRequest:success:failure:
 */
- (NSURLSessionDataTask *)PUT:(NSString *)URLString
                   parameters:(NSDictionary *)parameters
                      success:(void (^)(NSHTTPURLResponse *response, id responseObject))success
                      failure:(void (^)(NSError *error))failure;

/**
 Creates and runs an `NSURLSessionDataTask` with a `PATCH` request.

 @param path The path to be appended to the HTTP client's base URL and used as the request URL.
 @param parameters The parameters to be encoded according to the client request serializer.
 @param success A block object to be executed when the task finishes successfully. This block has no return value and takes two arguments: the server response, and the response object created by the client response serializer.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes a single arguments: the error describing the network or parsing error that occurred.

 @see -runDataTaskWithRequest:success:failure:
 */
- (NSURLSessionDataTask *)PATCH:(NSString *)URLString
                     parameters:(NSDictionary *)parameters
                        success:(void (^)(NSHTTPURLResponse *response, id responseObject))success
                        failure:(void (^)(NSError *error))failure;

/**
 Creates and runs an `NSURLSessionDataTask` with a `DELETE` request.

 @param path The path to be appended to the HTTP client's base URL and used as the request URL.
 @param parameters The parameters to be encoded according to the client request serializer.
 @param success A block object to be executed when the task finishes successfully. This block has no return value and takes two arguments: the server response, and the response object created by the client response serializer.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes a single arguments: the error describing the network or parsing error that occurred.

 @see -runDataTaskWithRequest:success:failure:
 */
- (NSURLSessionDataTask *)DELETE:(NSString *)URLString
                      parameters:(NSDictionary *)parameters
                         success:(void (^)(NSHTTPURLResponse *response, id responseObject))success
                         failure:(void (^)(NSError *error))failure;

///-------------------------
/// @name Running Data Tasks
///-------------------------

/**
 
 */
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                                      success:(void (^)(NSHTTPURLResponse *response, id <AFURLResponseSerialization> serializer, id responseObject))success
                                      failure:(void (^)(NSError *error))failure;


///---------------------------
/// @name Running Upload Tasks
///---------------------------

/**
 
 */
- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request
                                         fromFile:(NSURL *)fileURL
                                         progress:(void (^)(uint32_t bytesWritten, uint32_t totalBytesWritten, uint32_t totalBytesExpectedToWrite))progress
                                          success:(void (^)(NSHTTPURLResponse *response, id <AFURLResponseSerialization> serializer, id responseObject))success
                                          failure:(void (^)(NSError *error))failure;

/**
 
 */
- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request
                                         fromData:(NSData *)bodyData
                                         progress:(void (^)(uint32_t bytesWritten, uint32_t totalBytesWritten, uint32_t totalBytesExpectedToWrite))progress
                                          success:(void (^)(NSHTTPURLResponse *response, id <AFURLResponseSerialization> serializer, id responseObject))success
                                          failure:(void (^)(NSError *error))failure;

///-----------------------------
/// @name Running Download Tasks
///-----------------------------

/**
 
 */
- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request
                                             progress:(void (^)(uint32_t bytesRead, uint32_t totalBytesRead, uint32_t totalBytesExpectedToRead))progress
                                              success:(NSURL * (^)(NSHTTPURLResponse *response))success
                                              failure:(void (^)(NSError *error))failure;

/**
 
 */
- (NSURLSessionDownloadTask *)downloadTaskWithResumeData:(NSData *)resumeData
                                                progress:(void (^)(uint32_t bytesRead, uint32_t totalBytesRead, uint32_t totalBytesExpectedToRead))progress
                                                 success:(NSURL * (^)(NSHTTPURLResponse *response))success
                                                 failure:(void (^)(NSError *error))failure;

@end

///----------------
/// @name Constants
///----------------

/**
 ## Network Reachability

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

 ## Parameter Encoding

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

 The filename and MIME type for this data in the form will be automatically generated, using the last path component of the `fileURL` and system associated MIME type for the `fileURL` extension, respectively.
 
 @param fileURL The URL corresponding to the file whose content will be appended to the form. This parameter must not be `nil`.
 @param name The name to be associated with the specified data. This parameter must not be `nil`.
 @param error If an error occurs, upon return contains an `NSError` object that describes the problem.

 @return `YES` if the file data was successfully appended, otherwise `NO`.
 */
- (BOOL)appendPartWithFileURL:(NSURL *)fileURL
                         name:(NSString *)name
                        error:(NSError * __autoreleasing *)error;

/**
 Appends the HTTP header `Content-Disposition: file; filename=#{filename}; name=#{name}"` and `Content-Type: #{mimeType}`, followed by the encoded file data and the multipart form boundary.

 @param fileURL The URL corresponding to the file whose content will be appended to the form. This parameter must not be `nil`.
 @param name The name to be associated with the specified data. This parameter must not be `nil`.
 @param fileName The file name to be used in the `Content-Disposition` header. This parameter must not be `nil`.
 @param mimeType The declared MIME type of the file data. This parameter must not be `nil`.
 @param error If an error occurs, upon return contains an `NSError` object that describes the problem.

 @return `YES` if the file data was successfully appended otherwise `NO`.
 */
- (BOOL)appendPartWithFileURL:(NSURL *)fileURL
                         name:(NSString *)name
                     fileName:(NSString *)fileName
                     mimeType:(NSString *)mimeType
                        error:(NSError * __autoreleasing *)error;

/**
 Appends the HTTP header `Content-Disposition: file; filename=#{filename}; name=#{name}"` and `Content-Type: #{mimeType}`, followed by the data from the input stream and the multipart form boundary.

 @param inputStream The input stream to be appended to the form data
 @param name The name to be associated with the specified input stream. This parameter must not be `nil`.
 @param fileName The filename to be associated with the specified input stream. This parameter must not be `nil`.
 @param length The length of the specified input stream in bytes.
 @param mimeType The MIME type of the specified data. (For example, the MIME type for a JPEG image is image/jpeg.) For a list of valid MIME types, see http://www.iana.org/assignments/media-types/. This parameter must not be `nil`.
 */
- (void)appendPartWithInputStream:(NSInputStream *)inputStream
                             name:(NSString *)name
                         fileName:(NSString *)fileName
                           length:(int64_t)length
                         mimeType:(NSString *)mimeType;

/**
 Appends the HTTP header `Content-Disposition: file; filename=#{filename}; name=#{name}"` and `Content-Type: #{mimeType}`, followed by the encoded file data and the multipart form boundary.

 @param data The data to be encoded and appended to the form data.
 @param name The name to be associated with the specified data. This parameter must not be `nil`.
 @param fileName The filename to be associated with the specified data. This parameter must not be `nil`.
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

 When uploading over a 3G or EDGE connection, requests may fail with "request body stream exhausted". Setting a maximum packet size and delay according to the recommended values (`kAFUploadStream3GSuggestedPacketSize` and `kAFUploadStream3GSuggestedDelay`) lowers the risk of the input stream exceeding its allocated bandwidth. Unfortunately, as of iOS 6, there is no definite way to distinguish between a 3G, EDGE, or LTE connection. As such, it is not recommended that you throttle bandwidth based solely on network reachability. Instead, you should consider checking for the "request body stream exhausted" in a failure block, and then retrying the request with throttled bandwidth.

 @param numberOfBytes Maximum packet size, in number of bytes. The default packet size for an input stream is 32kb.
 @param delay Duration of delay each time a packet is read. By default, no delay is set.
 */
- (void)throttleBandwidthWithPacketSize:(NSUInteger)numberOfBytes
                                  delay:(NSTimeInterval)delay;

@end
