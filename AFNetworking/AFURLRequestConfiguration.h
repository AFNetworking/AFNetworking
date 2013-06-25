// AFURLRequestConfiguration.h
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

#import "AFSerialization.h"

// Necessary if most properties are configured on session now?

@interface AFURLRequestConfiguration : NSObject

@property (nonatomic, strong) NSURLComponents *URLComponents;

@property (nonatomic, assign) BOOL allowsCellularAccess;
@property (nonatomic, assign) BOOL shouldHandleCookies;
@property (nonatomic, assign) BOOL shouldUsePipelining;
@property (nonatomic, assign) NSURLRequestCachePolicy cachePolicy;
@property (nonatomic, assign) NSURLRequestNetworkServiceType networkServiceType;
@property (nonatomic, assign) NSTimeInterval timeoutInterval;

@property (nonatomic, strong) NSURLCredential *credential;

/**
 Default SSL pinning mode for each `AFHTTPRequestOperation` created by `HTTPRequestOperationWithRequest:success:failure:`.
 */
#ifdef _AFNETWORKING_PIN_SSL_CERTIFICATES_
@property (nonatomic, assign) AFURLConnectionOperationSSLPinningMode SSLPinningMode;
#endif

/**
 Whether each `AFHTTPRequestOperation` created by `HTTPRequestOperationWithRequest:success:failure:` should accept an invalid SSL certificate.

 If `_AFNETWORKING_ALLOW_INVALID_SSL_CERTIFICATES_` is set, this property defaults to `YES` for backwards compatibility. Otherwise, this property defaults to `NO`.
 */
@property (nonatomic, assign) BOOL allowsInvalidSSLCertificate;

+ (instancetype)defaultConfiguration;

///----------------------------------------
/// @name Managing HTTP Header Field Values
///----------------------------------------

@property (readonly, nonatomic, strong) NSDictionary *headers;

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


@end
