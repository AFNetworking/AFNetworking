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
#import "AFHTTPOperation.h"

@protocol AFRestClient <NSObject>
@required
+ (NSURL *)baseURL;
- (NSMutableURLRequest *)requestWithMethod:(NSString *)method path:(NSString *)path parameters:(NSDictionary *)parameters;
@end

@interface AFRestClient : NSObject <AFRestClient>
- (NSString *)defaultValueForHeader:(NSString *)header;
- (void)setDefaultHeader:(NSString *)header value:(NSString *)value;
- (void)setAuthorizationHeaderWithToken:(NSString *)token;
- (void)clearAuthorizationHeader;

- (void)getPath:(NSString *)path parameters:(NSDictionary *)parameters callback:(AFHTTPOperationCallback *)callback;
- (void)postPath:(NSString *)path parameters:(NSDictionary *)parameters callback:(AFHTTPOperationCallback *)callback;
- (void)putPath:(NSString *)path parameters:(NSDictionary *)parameters callback:(AFHTTPOperationCallback *)callback;
- (void)deletePath:(NSString *)path parameters:(NSDictionary *)parameters callback:(AFHTTPOperationCallback *)callback;

- (void)enqueueHTTPOperationWithRequest:(NSURLRequest *)request callback:(AFHTTPOperationCallback *)callback;
- (void)enqueueHTTPOperation:(AFHTTPOperation *)operation;
@end

#pragma mark - NSString + AFRestClient

@interface NSString (AFRestClient)
- (NSString *)urlEncodedString;
- (NSString *)urlEncodedStringWithEncoding:(NSStringEncoding)encoding;
@end
