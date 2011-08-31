// AFRestClient.m
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

#import "AFRestClient.h"
#import "AFJSONRequestOperation.h"

#import "NSData+AFNetworking.h"

static NSStringEncoding const kAFRestClientStringEncoding = NSUTF8StringEncoding;

@interface AFRestClient ()
@property (readwrite, nonatomic, retain) NSMutableDictionary *defaultHeaders;
@property (readwrite, nonatomic, retain) NSOperationQueue *operationQueue;
@end

@implementation AFRestClient
@synthesize defaultHeaders = _defaultHeaders;
@synthesize operationQueue = _operationQueue;

- (id)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.operationQueue = [[[NSOperationQueue alloc] init] autorelease];
	[self.operationQueue setMaxConcurrentOperationCount:2];
	
	self.defaultHeaders = [NSMutableDictionary dictionary];
    
    // Accept HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
	[self setDefaultHeader:@"Accept" value:@"application/json"];
    
	// Accept-Encoding HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.3
	[self setDefaultHeader:@"Accept-Encoding" value:@"gzip"];
	
	// Accept-Language HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.4
	NSString *preferredLanguageCodes = [[NSLocale preferredLanguages] componentsJoinedByString:@", "];
	[self setDefaultHeader:@"Accept-Language" value:[NSString stringWithFormat:@"%@, en-us;q=0.8", preferredLanguageCodes]];
	
	// User-Agent Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.43
	[self setDefaultHeader:@"User-Agent" value:[NSString stringWithFormat:@"%@/%@ (%@, %@ %@, %@, Scale/%f)", [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleIdentifierKey], [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey], @"unknown", [[UIDevice currentDevice] systemName], [[UIDevice currentDevice] systemVersion], [[UIDevice currentDevice] model], ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] ? [[UIScreen mainScreen] scale] : 1.0)]];
    
    // X-UDID HTTP Header
	[self setDefaultHeader:@"X-UDID" value:[[UIDevice currentDevice] uniqueIdentifier]];
    
    return self;
}

- (void)dealloc {
    [_defaultHeaders release];
    [_operationQueue release];
    [super dealloc];
}

+ (NSURL *)baseURL {
    if ([self class] == [AFRestClient class]) {
		[NSException raise:NSInternalInconsistencyException format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
	}
    
    return nil;
}

- (NSString *)defaultValueForHeader:(NSString *)header {
	return [self.defaultHeaders valueForKey:header];
}

- (void)setDefaultHeader:(NSString *)header value:(NSString *)value {
	[self.defaultHeaders setObject:value forKey:header];
}

- (void)setAuthorizationHeaderWithUsername:(NSString *)username password:(NSString *)password {
	NSString *authHeader = [NSString stringWithFormat:@"%@:%@", username, password];
    NSString *encodedAuthHeader = [[NSData dataWithBytes:[authHeader UTF8String] length:[authHeader length]] base64EncodedString];
    [self setDefaultHeader:@"Authorization" value:[NSString stringWithFormat:@"Basic %@", encodedAuthHeader]];
}

- (void)setAuthorizationHeaderWithToken:(NSString *)token {
    [self setDefaultHeader:@"Authorization" value:[NSString stringWithFormat:@"Token token=\"%@\"", token]];
}

- (void)clearAuthorizationHeader {
	[self.defaultHeaders removeObjectForKey:@"Authorization"];
}

#pragma mark -

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method path:(NSString *)path parameters:(NSDictionary *)parameters {	
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
	NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithDictionary:self.defaultHeaders];
	NSURL *url = [NSURL URLWithString:path relativeToURL:[[self class] baseURL]];
	
    if (parameters) {
        NSMutableArray *mutableParameterComponents = [NSMutableArray array];
        for (id key in [parameters allKeys]) {
            NSString *component = [NSString stringWithFormat:@"%@=%@", [[key description] urlEncodedStringWithEncoding:kAFRestClientStringEncoding], [[[parameters valueForKey:key] description] urlEncodedStringWithEncoding:kAFRestClientStringEncoding]];
            [mutableParameterComponents addObject:component];
        }
        NSString *queryString = [mutableParameterComponents componentsJoinedByString:@"&"];
        
        if ([method isEqualToString:@"GET"]) {
            url = [NSURL URLWithString:[[url absoluteString] stringByAppendingFormat:[path rangeOfString:@"?"].location == NSNotFound ? @"?%@" : @"&%@", queryString]];
        } else {
            NSString *charset = (NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(kAFRestClientStringEncoding));
            [headers setObject:[NSString stringWithFormat:@"application/x-www-form-urlencoded; charset=%@", charset] forKey:@"Content-Type"];
            [request setHTTPBody:[queryString dataUsingEncoding:NSUTF8StringEncoding]];
        }
    }
    
	[request setURL:url];
	[request setHTTPMethod:method];
	[request setHTTPShouldHandleCookies:NO];
	[request setAllHTTPHeaderFields:headers];
    
	return request;
}

- (void)enqueueHTTPOperationWithRequest:(NSURLRequest *)request success:(void (^)(id response))success failure:(void (^)(NSError *error))failure {
	if ([request URL] == nil || [[request URL] isEqual:[NSNull null]]) {
		return;
	}
    
    AFHTTPRequestOperation *operation = [AFJSONRequestOperation operationWithRequest:request success:success failure:failure];
    [self.operationQueue addOperation:operation];
}

- (void)cancelHTTPOperationsWithRequest:(NSURLRequest *)request {
    for (AFHTTPRequestOperation *operation in [self.operationQueue operations]) {
        if ([[operation request] isEqual:request]) {
            [operation cancel];
        }
    }
}

- (void)cancelAllHTTPOperations {
    [self.operationQueue cancelAllOperations];
}

#pragma mark -

- (void)getPath:(NSString *)path parameters:(NSDictionary *)parameters success:(void (^)(id response))success {
    [self getPath:path parameters:parameters success:success failure:nil];
}

- (void)getPath:(NSString *)path parameters:(NSDictionary *)parameters success:(void (^)(id response))success failure:(void (^)(NSError *error))failure {
	NSURLRequest *request = [self requestWithMethod:@"GET" path:path parameters:parameters];
	[self enqueueHTTPOperationWithRequest:request success:success failure:failure];
}

- (void)postPath:(NSString *)path parameters:(NSDictionary *)parameters success:(void (^)(id response))success {
    [self postPath:path parameters:parameters success:success failure:nil];
}

- (void)postPath:(NSString *)path parameters:(NSDictionary *)parameters success:(void (^)(id response))success failure:(void (^)(NSError *error))failure {
	NSURLRequest *request = [self requestWithMethod:@"POST" path:path parameters:parameters];
	[self enqueueHTTPOperationWithRequest:request success:success failure:failure];
}

- (void)putPath:(NSString *)path parameters:(NSDictionary *)parameters success:(void (^)(id response))success {
    [self putPath:path parameters:parameters success:success failure:nil];
}

- (void)putPath:(NSString *)path parameters:(NSDictionary *)parameters success:(void (^)(id response))success failure:(void (^)(NSError *error))failure {
	NSURLRequest *request = [self requestWithMethod:@"PUT" path:path parameters:parameters];
	[self enqueueHTTPOperationWithRequest:request success:success failure:failure];
}

- (void)deletePath:(NSString *)path parameters:(NSDictionary *)parameters success:(void (^)(id response))success {
    [self deletePath:path parameters:parameters success:success failure:nil];
}

- (void)deletePath:(NSString *)path parameters:(NSDictionary *)parameters success:(void (^)(id response))success failure:(void (^)(NSError *error))failure {
	NSURLRequest *request = [self requestWithMethod:@"DELETE" path:path parameters:parameters];
	[self enqueueHTTPOperationWithRequest:request success:success failure:failure];
}

@end
