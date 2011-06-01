// AFGowallaAPI.m
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

#import "AFGowallaAPI.h"
#import "AFHTTPOperation.h"

// Replace this with your own API Key, available at http://api.gowalla.com/api/keys/
NSString * const kAFGowallaClientID = @"e7ccb7d3d2414eb2af4663fc91eb2793";

static NSString * const kAFGowallaBaseURLString = @"https://api.gowalla.com/";

static NSStringEncoding const kAFStringEncoding = NSUTF8StringEncoding;

static NSMutableDictionary *_defaultHeaders = nil;
static NSOperationQueue *_operationQueue = nil;

@implementation AFGowallaAPI

+ (void)initialize {	
	_operationQueue = [[NSOperationQueue alloc] init];
	[_operationQueue setMaxConcurrentOperationCount:2];
	
	_defaultHeaders = [[NSMutableDictionary alloc] init];
	
	// Accept HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
	[self setDefaultHeader:@"Accept" value:@"application/json"];

	// Accept-Encoding HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.3
	[self setDefaultHeader:@"Accept-Encoding" value:@"gzip"];
	
	// Accept-Language HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.4
	NSString *preferredLanguageCodes = [[NSLocale preferredLanguages] componentsJoinedByString:@", "];
	[self setDefaultHeader:@"Accept-Language" value:[NSString stringWithFormat:@"%@, en-us;q=0.8", preferredLanguageCodes]];
	
	// User-Agent Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.43
	[self setDefaultHeader:@"User-Agent" value:[NSString stringWithFormat:@"AFNetworkingExample/%@ (%@, %@ %@, %@, Scale/%f)", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"], @"unknown", [[UIDevice currentDevice] systemName], [[UIDevice currentDevice] systemVersion], [[UIDevice currentDevice] model], ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] ? [[UIScreen mainScreen] scale] : 1.0)]];
	
	// X-Gowalla-API-Key HTTP Header; see http://api.gowalla.com/api/docs
	[self setDefaultHeader:@"X-Gowalla-API-Key" value:kAFGowallaClientID];
	
	// X-Gowalla-API-Version HTTP Header; see http://api.gowalla.com/api/docs
	[self setDefaultHeader:@"X-Gowalla-API-Version" value:@"1"];
	
	// X-UDID HTTP Header
	[self setDefaultHeader:@"X-UDID" value:[[UIDevice currentDevice] uniqueIdentifier]];
}

+ (NSString *)defaultValueForHeader:(NSString *)header {
	return [_defaultHeaders valueForKey:header];
}

+ (void)setDefaultHeader:(NSString *)header value:(NSString *)value {
	[_defaultHeaders setObject:value forKey:header];
}

+ (void)setAuthorizationHeaderWithToken:(NSString *)token {
    [self setDefaultHeader:@"Authorization" value:[NSString stringWithFormat:@"Token token=\"%@\"", token]];
}

+ (void)clearAuthorizationHeader {
	[_defaultHeaders removeObjectForKey:@"Authorization"];
}

+ (NSMutableURLRequest *)requestWithMethod:(NSString *)method path:(NSString *)path parameters:(NSDictionary *)parameters {	
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
	NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithDictionary:_defaultHeaders];
	NSURL *url = nil;
	
	NSMutableArray *mutableParameterComponents = [NSMutableArray array];
	for (id key in [parameters allKeys]) {
		NSString *component = [NSString stringWithFormat:@"%@=%@", [key urlEncodedStringWithEncoding:kAFStringEncoding], [[parameters valueForKey:key] urlEncodedStringWithEncoding:kAFStringEncoding]];
		[mutableParameterComponents addObject:component];
	}
	NSString *queryString = [mutableParameterComponents componentsJoinedByString:@"&"];
									
	if ([method isEqualToString:@"GET"]) {
		path = [path stringByAppendingFormat:[path rangeOfString:@"?"].location == NSNotFound ? @"?%@" : @"&%@", queryString];
		url = [NSURL URLWithString:path relativeToURL:[NSURL URLWithString:kAFGowallaBaseURLString]];
	} else {
		url = [NSURL URLWithString:path relativeToURL:[NSURL URLWithString:kAFGowallaBaseURLString]];
		NSString *charset = (NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(kAFStringEncoding));
		[headers setObject:[NSString stringWithFormat:@"application/x-www-form-urlencoded; charset=%@", charset] forKey:@"Content-Type"];
		[request setHTTPBody:[queryString dataUsingEncoding:NSUTF8StringEncoding]];
	}

	[request setURL:url];
	[request setHTTPMethod:method];
	[request setHTTPShouldHandleCookies:NO];
	[request setAllHTTPHeaderFields:headers];

	return request;
}

+ (void)enqueueHTTPOperationWithRequest:(NSURLRequest *)request callback:(AFHTTPOperationCallback *)callback {
	if ([request URL] == nil || [[request URL] isEqual:[NSNull null]]) {
		return;
	}
	
	AFHTTPOperation *operation = [[[AFHTTPOperation alloc] initWithRequest:request callback:callback] autorelease];
    [self enqueueHTTPOperation:operation];
}

+ (void)enqueueHTTPOperation:(AFHTTPOperation *)operation {
    [_operationQueue addOperation:operation];
}

#pragma mark -
#pragma mark HTTP Methods

+ (void)getPath:(NSString *)path parameters:(NSDictionary *)parameters callback:(AFHTTPOperationCallback *)callback {
	NSURLRequest *request = [self requestWithMethod:@"GET" path:path parameters:parameters];
	[self enqueueHTTPOperationWithRequest:request callback:callback];
}

+ (void)postPath:(NSString *)path parameters:(NSDictionary *)parameters callback:(AFHTTPOperationCallback *)callback  {
	NSURLRequest *request = [self requestWithMethod:@"POST" path:path parameters:parameters];
	[self enqueueHTTPOperationWithRequest:request callback:callback];
}

+ (void)putPath:(NSString *)path parameters:(NSDictionary *)parameters callback:(AFHTTPOperationCallback *)callback  {
	NSURLRequest *request = [self requestWithMethod:@"PUT" path:path parameters:parameters];
	[self enqueueHTTPOperationWithRequest:request callback:callback];
}

+ (void)deletePath:(NSString *)path parameters:(NSDictionary *)parameters callback:(AFHTTPOperationCallback *)callback  {
	NSURLRequest *request = [self requestWithMethod:@"DELETE" path:path parameters:parameters];
	[self enqueueHTTPOperationWithRequest:request callback:callback];
}

@end

#pragma mark -
#pragma mark -

@implementation NSString (AFGowallaAPI)

// See http://github.com/pokeb/asi-http-request/raw/master/Classes/ASIFormDataRequest.m
- (NSString*)urlEncodedString { 
	return [self urlEncodedStringWithEncoding:NSUTF8StringEncoding];
}

- (NSString *)urlEncodedStringWithEncoding:(NSStringEncoding)encoding { 
	NSString *newString = [(NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)self, NULL, CFSTR(":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`"), CFStringConvertNSStringEncodingToEncoding(encoding)) autorelease];
	
	if (newString) {
		return newString;
	}
	
	return @"";
}

@end
