// AFHTTPClient.m
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

#import "AFHTTPClient.h"
#import "AFJSONRequestOperation.h"

static NSString * const kAFMultipartFormLineDelimiter = @"\r\n"; // CRLF
static NSString * const kAFMultipartFormBoundary = @"Boundary+0xAbCdEfGbOuNdArY";

static NSString * AFMultipartFormEncapsulationBoundary() {
    return [NSString stringWithFormat:@"--%@", kAFMultipartFormBoundary];
}

static NSString * AFMultipartFormFinalBoundary() {
    return [NSString stringWithFormat:@"--%@--", kAFMultipartFormBoundary];
}

@interface AFMutableMultipartFormData : NSMutableData <AFMultipartFormDataProxy> {
@private
    NSStringEncoding _stringEncoding;
    NSRange _finalBoundaryRange;
}

- (id)initWithStringEncoding:(NSStringEncoding)encoding;

@end

#pragma mark -

static NSString * AFBase64EncodedStringFromString(NSString *string) {
    NSData *data = [NSData dataWithBytes:[string UTF8String] length:[string length]];
    NSUInteger length = [data length];
    NSMutableData *mutableData = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    
    uint8_t *input = (uint8_t *)[data bytes];
    uint8_t *output = (uint8_t *)[mutableData mutableBytes];
    
    for (NSUInteger i = 0; i < length; i += 3) {
        NSUInteger value = 0;
        for (NSUInteger j = i; j < (i + 3); j++) {
            value <<= 8;
            if (j < length) {
                value |= (0xFF & input[j]); 
            }
        }
        
        static char const kAFBase64EncodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

        NSInteger idx = (i / 3) * 4;
        output[idx + 0] = kAFBase64EncodingTable[(value >> 18) & 0x3F];
        output[idx + 1] = kAFBase64EncodingTable[(value >> 12) & 0x3F];
        output[idx + 2] = (i + 1) < length ? kAFBase64EncodingTable[(value >> 6)  & 0x3F] : '=';
        output[idx + 3] = (i + 2) < length ? kAFBase64EncodingTable[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[[NSString alloc] initWithData:mutableData encoding:NSASCIIStringEncoding] autorelease];
}

static NSString * AFURLEncodedStringFromStringWithEncoding(NSString *string, NSStringEncoding encoding) {
    static NSString * const kAFLegalCharactersToBeEscaped = @"?!@#$^&%*+,:;='\"`<>()[]{}/\\|~ ";
    
	return [(NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)string, NULL, (CFStringRef)kAFLegalCharactersToBeEscaped, CFStringConvertNSStringEncodingToEncoding(encoding)) autorelease];
}

@interface AFHTTPClient ()
@property (readwrite, nonatomic, retain) NSURL *baseURL;
@property (readwrite, nonatomic, retain) NSMutableDictionary *defaultHeaders;
@property (readwrite, nonatomic, retain) NSOperationQueue *operationQueue;
@end

@implementation AFHTTPClient
@synthesize baseURL = _baseURL;
@synthesize stringEncoding = _stringEncoding;
@synthesize defaultHeaders = _defaultHeaders;
@synthesize operationQueue = _operationQueue;

+ (AFHTTPClient *)clientWithBaseURL:(NSURL *)url {
    return [[[self alloc] initWithBaseURL:url] autorelease];
}

- (id)initWithBaseURL:(NSURL *)url {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.baseURL = url;
    
    self.stringEncoding = NSUTF8StringEncoding;
	
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
    
    self.operationQueue = [[[NSOperationQueue alloc] init] autorelease];
	[self.operationQueue setMaxConcurrentOperationCount:2];
    
    return self;
}

- (void)dealloc {
    [_baseURL release];
    [_defaultHeaders release];
    [_operationQueue release];
    [super dealloc];
}

- (NSString *)defaultValueForHeader:(NSString *)header {
	return [self.defaultHeaders valueForKey:header];
}

- (void)setDefaultHeader:(NSString *)header value:(NSString *)value {
	[self.defaultHeaders setObject:value forKey:header];
}

- (void)setAuthorizationHeaderWithUsername:(NSString *)username password:(NSString *)password {
	NSString *basicAuthCredentials = [NSString stringWithFormat:@"%@:%@", username, password];
    [self setDefaultHeader:@"Authorization" value:[NSString stringWithFormat:@"Basic %@", AFBase64EncodedStringFromString(basicAuthCredentials)]];
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
	NSURL *url = [NSURL URLWithString:path relativeToURL:self.baseURL];
	
    if (parameters) {
        NSMutableArray *mutableParameterComponents = [NSMutableArray array];
        for (id key in [parameters allKeys]) {
            NSString *component = [NSString stringWithFormat:@"%@=%@", AFURLEncodedStringFromStringWithEncoding([key description], self.stringEncoding), AFURLEncodedStringFromStringWithEncoding([[parameters valueForKey:key] description], self.stringEncoding)];
            [mutableParameterComponents addObject:component];
        }
        NSString *queryString = [mutableParameterComponents componentsJoinedByString:@"&"];
        
        if ([method isEqualToString:@"GET"]) {
            url = [NSURL URLWithString:[[url absoluteString] stringByAppendingFormat:[path rangeOfString:@"?"].location == NSNotFound ? @"?%@" : @"&%@", queryString]];
        } else {
            NSString *charset = (NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(self.stringEncoding));
            [headers setObject:[NSString stringWithFormat:@"application/x-www-form-urlencoded; charset=%@", charset] forKey:@"Content-Type"];
            [request setHTTPBody:[queryString dataUsingEncoding:self.stringEncoding]];
        }
    }
    
	[request setURL:url];
	[request setHTTPMethod:method];
	[request setHTTPShouldHandleCookies:NO];
	[request setAllHTTPHeaderFields:headers];
    
	return request;
}

- (NSMutableURLRequest *)multipartFormRequestWithMethod:(NSString *)method
                                                   path:(NSString *)path
                                             parameters:(NSDictionary *)parameters
                              constructingBodyWithBlock:(void (^)(id <AFMultipartFormDataProxy>formData))block
{
    if (!([method isEqualToString:@"POST"] || [method isEqualToString:@"PUT"] || [method isEqualToString:@"DELETE"])) {
        [NSException raise:@"Invalid HTTP Method" format:@"%@ is not supported for multipart form requests; must be either POST, PUT, or DELETE", method];
        return nil;
    }
    
    NSMutableURLRequest *request = [self requestWithMethod:method path:path parameters:nil];
    __block AFMutableMultipartFormData *formData = [[AFMutableMultipartFormData alloc] initWithStringEncoding:self.stringEncoding];
    
    id key = nil;
	NSEnumerator *enumerator = [parameters keyEnumerator];
	while ((key = [enumerator nextObject])) {
        id value = [parameters valueForKey:key];
        NSData *data = nil;
        
        if ([value isKindOfClass:[NSData class]]) {
            data = value;
        } else {
            data = [[value description] dataUsingEncoding:self.stringEncoding];
        }
        
        [formData appendPartWithHeaders:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"form-data; name=\"%@\"", [key description]] forKey:@"Content-Disposition"] body:value];
    }
    
    if (block) {
        block(formData);
    }
    
    [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", kAFMultipartFormBoundary] forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:formData];
    
    [formData autorelease];
    
    return request;
}

- (void)enqueueHTTPOperationWithRequest:(NSURLRequest *)request success:(void (^)(id response))success failure:(void (^)(NSError *error))failure {
	if ([request URL] == nil || [[request URL] isEqual:[NSNull null]]) {
		return;
	}
    
    AFHTTPRequestOperation *operation = [AFJSONRequestOperation operationWithRequest:request success:success failure:failure];
    [self.operationQueue addOperation:operation];
}

- (void)cancelHTTPOperationsWithMethod:(NSString *)method andURL:(NSURL *)url {
    for (AFHTTPRequestOperation *operation in [self.operationQueue operations]) {
        if ([[[operation request] HTTPMethod] isEqualToString:method] && [[[operation request] URL] isEqual:url]) {
            [operation cancel];
        }
    }
}

#pragma mark -

- (void)getPath:(NSString *)path parameters:(NSDictionary *)parameters success:(void (^)(id response))success failure:(void (^)(NSError *error))failure {
	NSURLRequest *request = [self requestWithMethod:@"GET" path:path parameters:parameters];
	[self enqueueHTTPOperationWithRequest:request success:success failure:failure];
}

- (void)postPath:(NSString *)path parameters:(NSDictionary *)parameters success:(void (^)(id response))success failure:(void (^)(NSError *error))failure {
	NSURLRequest *request = [self requestWithMethod:@"POST" path:path parameters:parameters];
	[self enqueueHTTPOperationWithRequest:request success:success failure:failure];
}

- (void)putPath:(NSString *)path parameters:(NSDictionary *)parameters success:(void (^)(id response))success failure:(void (^)(NSError *error))failure {
	NSURLRequest *request = [self requestWithMethod:@"PUT" path:path parameters:parameters];
	[self enqueueHTTPOperationWithRequest:request success:success failure:failure];
}

- (void)deletePath:(NSString *)path parameters:(NSDictionary *)parameters success:(void (^)(id response))success failure:(void (^)(NSError *error))failure {
	NSURLRequest *request = [self requestWithMethod:@"DELETE" path:path parameters:parameters];
	[self enqueueHTTPOperationWithRequest:request success:success failure:failure];
}

@end

#pragma mark -

// multipart/form-data; see http://www.w3.org/TR/html4/interact/forms.html#h-17.13.4.2
@interface AFMutableMultipartFormData ()
@property (readwrite, nonatomic, assign) NSStringEncoding stringEncoding;
@property (readwrite, nonatomic, assign) NSRange finalBoundaryRange;

- (void)appendBlankLine;
@end

@implementation AFMutableMultipartFormData
@synthesize stringEncoding = _stringEncoding;
@synthesize finalBoundaryRange = _finalBoundaryRange;

- (id)initWithStringEncoding:(NSStringEncoding)encoding {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.stringEncoding = encoding;
    self.finalBoundaryRange = NSMakeRange(0, 0);
    
    return self;
}

#pragma mark - AFMultipartFormDataProxy

- (void)appendPartWithHeaders:(NSDictionary *)headers body:(NSData *)body {
    if ([self length] > 0) {
        [self appendString:AFMultipartFormEncapsulationBoundary()];
    }
    
    for (NSString *field in [headers allKeys]) {
        [self appendString:[NSString stringWithFormat:@"%@: %@", field, [headers valueForKey:field]]];
    }
    
    [self appendBlankLine];
    [self appendData:body];
}

- (void)appendPartWithFormData:(NSData *)data mimeType:(NSString *)mimeType name:(NSString *)name {
    NSMutableDictionary *mutableHeaders = [NSMutableDictionary dictionary];
    [mutableHeaders setValue:[NSString stringWithFormat:@"form-data; name=\"%@\"", name] forKey:@"Content-Disposition"];
    if (mimeType) {
        [mutableHeaders setValue:mimeType forKey:@"Content-Type"];
    }
    
    [self appendPartWithHeaders:mutableHeaders body:data];
}

- (void)appendPartWithFile:(NSURL *)fileURL mimeType:(NSString *)mimeType fileName:(NSString *)fileName {
    if (![fileURL isFileURL]) {
        [NSException raise:@"Invalid fileURL value" format:@"%@ must be a valid file URL", fileURL];
        return;
    }
    
    NSMutableDictionary *mutableHeaders = [NSMutableDictionary dictionary];
    [mutableHeaders setValue:[NSString stringWithFormat:@"file; filename=\"%@\"", fileName] forKey:@"Content-Disposition"];
    [mutableHeaders setValue:mimeType forKey:@"Content-Type"];
    
    NSData *data = [NSData dataWithContentsOfFile:[fileURL absoluteString]];
    
    [self appendPartWithHeaders:mutableHeaders body:data];
}

- (void)appendData:(NSData *)data {
    NSMutableData *mutableData = [NSMutableData dataWithData:data];
    [self replaceBytesInRange:self.finalBoundaryRange withBytes:[mutableData bytes]];
    
    NSData *finalBoundary = [AFMultipartFormFinalBoundary() dataUsingEncoding:self.stringEncoding];
    self.finalBoundaryRange = NSMakeRange([self length], [finalBoundary length]);
    [super appendData:finalBoundary];
}

- (void)appendString:(NSString *)string {
    [self appendData:[string dataUsingEncoding:self.stringEncoding]];
}

- (void)appendBlankLine {
    [self appendString:@""];
}

@end
