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

#import "AFHTTPRequestOperation.h"

/**
 
 */
@protocol AFURLRequestSerialization <NSCoding, NSCopying>

/**
 
 */
- (NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request
                               withParameters:(NSDictionary *)parameters
                                        error:(NSError *__autoreleasing *)error;

@end

/**
 
 */
@protocol AFURLResponseSerialization <NSCoding, NSCopying>

/**
 
 */
- (BOOL)canProcessResponse:(NSHTTPURLResponse *)response;

/**
 
 */
- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error;

@end

#pragma mark -

/**
 
 */
typedef NS_ENUM(NSUInteger, AFHTTPRequestQueryStringSerializationStyle) {
    AFHTTPRequestQueryStringDefaultStyle = 0,
};

/**
 
 */
@interface AFHTTPSerializer : NSObject <AFURLRequestSerialization, AFURLResponseSerialization>

@property (nonatomic, assign) NSStringEncoding *stringEncoding;

#pragma mark AFURLRequestSerialization

///---------------------------------------
/// @name Configuring HTTP Request Headers
///---------------------------------------

/**
 
 */
@property (readonly, nonatomic, strong) NSDictionary *HTTPRequestHeaders;

/**

 */
+ (instancetype)serializer;

/**
 Sets the value for the HTTP headers set in request objects made by the HTTP client. If `nil`, removes the existing value for that header.

 @param header The HTTP header to set a default value for
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
 `GET`, `HEAD`, and `DELETE` by default.
 */
@property (nonatomic, strong) NSSet *HTTPMethodsEncodingParametersInURI;

/**
 
 */
- (void)setQueryStringSerializationWithStyle:(AFHTTPRequestQueryStringSerializationStyle)style;

/**
 
 */
- (void)setQueryStringSerializationWithBlock:(NSString * (^)(NSURLRequest *request, NSDictionary *parameters, NSError *__autoreleasing *error))block;

///-----------------------------------------
/// @name Configuring Response Serialization
///-----------------------------------------

/**
 
 */
@property (nonatomic, strong) NSIndexSet *acceptableStatusCodes;

/**
 
 */
@property (nonatomic, strong) NSSet *acceptableContentTypes;

/**
 
 */
- (BOOL)validateResponse:(NSHTTPURLResponse *)response
                    data:(NSData *)data
                   error:(NSError *__autoreleasing *)error;

@end

#pragma mark -

/**
 
 */
@interface AFJSONSerializer : AFHTTPSerializer

/**
 
 */
@property (nonatomic, assign) NSJSONReadingOptions readingOptions;

/**
 
 */
@property (nonatomic, assign) NSJSONWritingOptions writingOptions;

/**
 
 */
+ (instancetype)serializerWithReadingOptions:(NSJSONReadingOptions)readingOptions
                              writingOptions:(NSJSONWritingOptions)writingOptions;

@end

#pragma mark -

/**
 
 */
@interface AFXMLParserSerializer : AFHTTPSerializer

@end

#pragma mark -

#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED

@interface AFXMLDocumentSerializer : AFHTTPSerializer

@property (nonatomic, assign) NSUInteger options;

/**

 */
+ (instancetype)serializerWithXMLDocumentOptions:(NSUInteger)mask;

@end

#endif

#pragma mark -

/**
 
 */
@interface AFPropertyListSerializer : AFHTTPSerializer

/**
 
 */
@property (nonatomic, assign) NSPropertyListFormat format;

/**
 
 */
@property (nonatomic, assign) NSPropertyListReadOptions readOptions;

/**
 
 */
@property (nonatomic, assign) NSPropertyListWriteOptions writeOptions;

/**
 
 */
+ (instancetype)serializerWithFormat:(NSPropertyListFormat)format
                         readOptions:(NSPropertyListReadOptions)readOptions
                        writeOptions:(NSPropertyListWriteOptions)writeOptions;

@end

#pragma mark -

/**
 
 */
@interface AFImageSerializer : AFHTTPSerializer

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
/**
 The scale factor used when interpreting the image data to construct `responseImage`. Specifying a scale factor of 1.0 results in an image whose size matches the pixel-based dimensions of the image. Applying a different scale factor changes the size of the image as reported by the size property. This is set to the value of scale of the main screen by default, which automatically scales images for retina displays, for instance.
 */
@property (nonatomic, assign) CGFloat imageScale;

/**
 Whether to automatically inflate response image data for compressed formats (such as PNG or JPEG). Enabling this can significantly improve drawing performance on iOS when used with `setCompletionBlockWithSuccess:failure:`, as it allows a bitmap representation to be constructed in the background rather than on the main thread. `YES` by default.
 */
@property (nonatomic, assign) BOOL automaticallyInflatesResponseImage;
#endif

@end
