// AFSerialization.h
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
#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
#import <UIKit/UIKit.h>
#endif

/**
 The `AFURLRequestSerialization` protocol is adopted by an object that encodes parameters for a specified HTTP requests. Request serializers may encode parameters as query strings, HTTP bodies, setting the appropriate HTTP header fields as necessary.

 For example, a JSON request serializer may set the HTTP body of the request to a JSON representation, and set the `Content-Type` HTTP header field value to `application/json`.
 */
@protocol AFURLRequestSerialization <NSObject, NSCoding, NSCopying>

/**
 Returns a request with the specified parameters encoded into a copy of the original request.

 @param request The original request.
 @param parameters The parameters to be encoded.
 @param error The error that occurred while attempting to encode the request parameters.

 @return A serialized request.
 */
- (NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request
                               withParameters:(NSDictionary *)parameters
                                        error:(NSError *__autoreleasing *)error;

@end

#pragma mark -

/**

 */
typedef NS_ENUM(NSUInteger, AFHTTPRequestQueryStringSerializationStyle) {
    AFHTTPRequestQueryStringDefaultStyle = 0,
};

@protocol AFMultipartFormData;

/**
 `AFHTTPSerializer` conforms to the `AFURLRequestSerialization` & `AFURLResponseSerialization` protocols, offering a concrete base implementation of query string / URL form-encoded parameter serialization and default request headers, as well as response status code and content type validation.

 Any request or response serializer dealing with HTTP is encouraged to subclass `AFHTTPSerializer` in order to ensure consistent default behavior.
 */
@interface AFHTTPRequestSerializer : NSObject <AFURLRequestSerialization>

/**
 The string encoding used to serialize parameters.
 */
@property (nonatomic, assign) NSStringEncoding stringEncoding;

///---------------------------------------
/// @name Configuring HTTP Request Headers
///---------------------------------------

/**
 Default HTTP header field values to be applied to serialized requests.
 */
@property (readonly, nonatomic, strong) NSDictionary *HTTPRequestHeaders;

/**
 Creates and returns a serializer with default configuration.
 */
+ (instancetype)serializer;

/**
 Sets the value for the HTTP headers set in request objects made by the HTTP client. If `nil`, removes the existing value for that header.

 @param field The HTTP header to set a default value for
 @param value The value set as default for the specified header, or `nil`
 */
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;

/**
 Sets the "Authorization" HTTP header set in request objects made by the HTTP client to a basic authentication value with Base64-encoded username and password. This overwrites any existing value for this header.

 @param username The HTTP basic auth username
 @param password The HTTP basic auth password
 */
- (void)setAuthorizationHeaderFieldWithUsername:(NSString *)username
                                       password:(NSString *)password;

/**
 Sets the "Authorization" HTTP header set in request objects made by the HTTP client to a token-based authentication value, such as an OAuth access token. This overwrites any existing value for this header.

 @param token The authentication token
 */
- (void)setAuthorizationHeaderFieldWithToken:(NSString *)token;


/**
 Clears any existing value for the "Authorization" HTTP header.
 */
- (void)clearAuthorizationHeader;

///-------------------------------------------------------
/// @name Configuring Query String Parameter Serialization
///-------------------------------------------------------

/**
 HTTP methods for which serialized requests will encode parameters as a query string. `GET`, `HEAD`, and `DELETE` by default.
 */
@property (nonatomic, strong) NSSet *HTTPMethodsEncodingParametersInURI;

/**
 Set the method of query string serialization according to one of the pre-defined styles.

 @param style The serialization style.

 @see AFHTTPRequestQueryStringSerializationStyle
 */
- (void)setQueryStringSerializationWithStyle:(AFHTTPRequestQueryStringSerializationStyle)style;

/**
 Set the a custom method of query string serialization according to the specified block.

 @param block A block that defines a process of encoding parameters into a query string. This block returns the query string and takes three arguments: the request, the parameters to encode, and the error that occurred when attempting to encode parameters for the given request.
 */
- (void)setQueryStringSerializationWithBlock:(NSString * (^)(NSURLRequest *request, NSDictionary *parameters, NSError *__autoreleasing *error))block;

///-------------------------------
/// @name Creating Request Objects
///-------------------------------

/**
 Creates an `NSMutableURLRequest` object with the specified HTTP method and URL string.

 If the HTTP method is `GET`, `HEAD`, or `DELETE`, the parameters will be used to construct a url-encoded query string that is appended to the request's URL. Otherwise, the parameters will be encoded according to the value of the `parameterEncoding` property, and set as the request body.

 @param method The HTTP method for the request, such as `GET`, `POST`, `PUT`, or `DELETE`. This parameter must not be `nil`.
 @param URLString The URL string used to create the request URL.
 @param parameters The parameters to be either set as a query string for `GET` requests, or the request HTTP body.

 @return An `NSMutableURLRequest` object.
 */
- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                 URLString:(NSString *)URLString
                                parameters:(NSDictionary *)parameters;

/**
 Creates an `NSMutableURLRequest` object with the specified HTTP method and URLString, and constructs a `multipart/form-data` HTTP body, using the specified parameters and multipart form data block. See http://www.w3.org/TR/html4/interact/forms.html#h-17.13.4.2

 Multipart form requests are automatically streamed, reading files directly from disk along with in-memory data in a single HTTP body. The resulting `NSMutableURLRequest` object has an `HTTPBodyStream` property, so refrain from setting `HTTPBodyStream` or `HTTPBody` on this request object, as it will clear out the multipart form body stream.

 @param method The HTTP method for the request. This parameter must not be `GET` or `HEAD`, or `nil`.
 @param URLString The URL string used to create the request URL.
 @param parameters The parameters to be encoded and set in the request HTTP body.
 @param block A block that takes a single argument and appends data to the HTTP body. The block argument is an object adopting the `AFMultipartFormData` protocol.

 @return An `NSMutableURLRequest` object
 */
- (NSMutableURLRequest *)multipartFormRequestWithMethod:(NSString *)method
                                              URLString:(NSString *)URLString
                                             parameters:(NSDictionary *)parameters
                              constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block;

@end

#pragma mark -

extern NSUInteger const kAFUploadStream3GSuggestedPacketSize;
extern NSTimeInterval const kAFUploadStream3GSuggestedDelay;

/**
 The `AFMultipartFormData` protocol defines the methods supported by the parameter in the block argument of `AFHTTPRequestSerializer -multipartFormRequestWithMethod:URLString:parameters:constructingBodyWithBlock:`.
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

 When uploading over a 3G or EDGE connection, requests may fail with "request body stream exhausted". Setting a maximum packet size and delay according to the recommended values (`kAFUploadStream3GSuggestedPacketSize` and `kAFUploadStream3GSuggestedDelay`) lowers the risk of the input stream exceeding its allocated bandwidth. Unfortunately, there is no definite way to distinguish between a 3G, EDGE, or LTE connection over `NSURLConnection`. As such, it is not recommended that you throttle bandwidth based solely on network reachability. Instead, you should consider checking for the "request body stream exhausted" in a failure block, and then retrying the request with throttled bandwidth.

 @param numberOfBytes Maximum packet size, in number of bytes. The default packet size for an input stream is 16kb.
 @param delay Duration of delay each time a packet is read. By default, no delay is set.
 */
- (void)throttleBandwidthWithPacketSize:(NSUInteger)numberOfBytes
                                  delay:(NSTimeInterval)delay;

@end

///----------------
/// @name Constants
///----------------

/**
 ## Throttling Bandwidth for HTTP Request Input Streams

 @see -throttleBandwidthWithPacketSize:delay:

 `kAFUploadStream3GSuggestedPacketSize`
 Maximum packet size, in number of bytes. Equal to 16kb.

 `kAFUploadStream3GSuggestedDelay`
 Duration of delay each time a packet is read. Equal to 0.2 seconds.
 */

#pragma mark -

@interface AFJSONRequestSerializer : AFHTTPRequestSerializer

/**
 The property list format. Possible values are described in "NSPropertyListFormat".
 */
@property (nonatomic, assign) NSPropertyListFormat format;

/**
 Options for writing the request JSON data from Foundation objects. For possible values, see the `NSJSONSerialization` documentation section "NSJSONWritingOptions". `0` by default.
 */
@property (nonatomic, assign) NSJSONWritingOptions writingOptions;

/**
 Creates and returns a JSON serializer with specified reading and writing options.

 @param writingOptions The specified JSON writing options.
 */
+ (instancetype)serializerWithWritingOptions:(NSJSONWritingOptions)writingOptions;

@end

@interface AFPropertyListRequestSerializer : AFHTTPRequestSerializer

/**
 The property list format. Possible values are described in "NSPropertyListFormat".
 */
@property (nonatomic, assign) NSPropertyListFormat format;

/**
 @warning The `writeOptions` property is currently unused.
 */
@property (nonatomic, assign) NSPropertyListWriteOptions writeOptions;

/**
 Creates and returns a property list serializer with a specified format, read options, and write options.

 @param format The property list format.
 @param writeOptions The property list write options.
 
 @warning The `writeOptions` property is currently unused.
 */
+ (instancetype)serializerWithFormat:(NSPropertyListFormat)format
                        writeOptions:(NSPropertyListWriteOptions)writeOptions;

@end
