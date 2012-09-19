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

#import <Foundation/Foundation.h>

#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"

#import <Availability.h>

#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <UIKit/UIKit.h>
#endif

#ifdef _SYSTEMCONFIGURATION_H
#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>
#endif

// Workaround for management of dispatch_retain() / dispatch_release() by ARC with iOS 6 / Mac OS X 10.8
#if (defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && (!defined(__IPHONE_6_0) || __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0)) || \
    (defined(__MAC_OS_X_VERSION_MIN_REQUIRED) && (!defined(__MAC_10_8) || __MAC_OS_X_VERSION_MIN_REQUIRED < __MAC_10_8))
#define AF_DISPATCH_RETAIN_RELEASE 1
#endif

@interface AFMultipartFormData : NSObject <AFMultipartFormData>

- (id)initWithURLRequest:(NSMutableURLRequest *)request
          stringEncoding:(NSStringEncoding)encoding;

- (NSMutableURLRequest *)requestByFinalizingMultipartFormData;

@end

#pragma mark -

#ifdef _SYSTEMCONFIGURATION_H
NSString * const AFNetworkingReachabilityDidChangeNotification = @"com.alamofire.networking.reachability.change";
NSString * const AFNetworkingReachabilityNotificationStatusItem = @"AFNetworkingReachabilityNotificationStatusItem";

typedef SCNetworkReachabilityRef AFNetworkReachabilityRef;
typedef void (^AFNetworkReachabilityStatusBlock)(AFNetworkReachabilityStatus status);
#else
typedef id AFNetworkReachabilityRef;
#endif

typedef void (^AFCompletionBlock)(void);

static NSString * AFBase64EncodedStringFromString(NSString *string) {
    NSData *data = [NSData dataWithBytes:[string UTF8String] length:[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
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
        
        static uint8_t const kAFBase64EncodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        
        NSUInteger idx = (i / 3) * 4;
        output[idx + 0] = kAFBase64EncodingTable[(value >> 18) & 0x3F];
        output[idx + 1] = kAFBase64EncodingTable[(value >> 12) & 0x3F];
        output[idx + 2] = (i + 1) < length ? kAFBase64EncodingTable[(value >> 6)  & 0x3F] : '=';
        output[idx + 3] = (i + 2) < length ? kAFBase64EncodingTable[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[NSString alloc] initWithData:mutableData encoding:NSASCIIStringEncoding];
}

static NSString * AFPercentEscapedQueryStringPairMemberFromStringWithEncoding(NSString *string, NSStringEncoding encoding) {
    // Escape characters that are legal in URIs, but have unintentional semantic significance when used in a query string parameter
    static NSString * const kAFLegalCharactersToBeEscaped = @":/.?&=;+!@$()~";
    
	return (__bridge_transfer  NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, NULL, (__bridge CFStringRef)kAFLegalCharactersToBeEscaped, CFStringConvertNSStringEncodingToEncoding(encoding));
}

#pragma mark -

@interface AFQueryStringPair : NSObject
@property (readwrite, nonatomic, retain) id field;
@property (readwrite, nonatomic, retain) id value;

- (id)initWithField:(id)field value:(id)value;
- (NSString *)URLEncodedStringValueWithEncoding:(NSStringEncoding)stringEncoding;

@end

@implementation AFQueryStringPair
@synthesize field = _field;
@synthesize value = _value;

- (id)initWithField:(id)field value:(id)value {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.field = field;
    self.value = value;
    
    return self;
}

- (NSString *)URLEncodedStringValueWithEncoding:(NSStringEncoding)stringEncoding {
    return [NSString stringWithFormat:@"%@=%@", AFPercentEscapedQueryStringPairMemberFromStringWithEncoding(self.field, stringEncoding), AFPercentEscapedQueryStringPairMemberFromStringWithEncoding([self.value description], stringEncoding)];
}

@end

#pragma mark -

extern NSArray * AFQueryStringPairsFromDictionary(NSDictionary *dictionary);
extern NSArray * AFQueryStringPairsFromKeyAndValue(NSString *key, id value);

NSString * AFQueryStringFromParametersWithEncoding(NSDictionary *parameters, NSStringEncoding stringEncoding) {
    NSMutableArray *mutablePairs = [NSMutableArray array];
    for (AFQueryStringPair *pair in AFQueryStringPairsFromDictionary(parameters)) {
        [mutablePairs addObject:[pair URLEncodedStringValueWithEncoding:stringEncoding]];
    }
    
    return [mutablePairs componentsJoinedByString:@"&"];
}

NSArray * AFQueryStringPairsFromDictionary(NSDictionary *dictionary) {
    return AFQueryStringPairsFromKeyAndValue(nil, dictionary);
}

NSArray * AFQueryStringPairsFromKeyAndValue(NSString *key, id value) {
    NSMutableArray *mutableQueryStringComponents = [NSMutableArray array];
    
    if([value isKindOfClass:[NSDictionary class]]) {
        [value enumerateKeysAndObjectsUsingBlock:^(id nestedKey, id nestedValue, BOOL *stop) {
            [mutableQueryStringComponents addObjectsFromArray:AFQueryStringPairsFromKeyAndValue((key ? [NSString stringWithFormat:@"%@[%@]", key, nestedKey] : nestedKey), nestedValue)];
        }];
    } else if([value isKindOfClass:[NSArray class]]) {
        [value enumerateObjectsUsingBlock:^(id nestedValue, NSUInteger idx, BOOL *stop) {
            [mutableQueryStringComponents addObjectsFromArray:AFQueryStringPairsFromKeyAndValue([NSString stringWithFormat:@"%@[]", key], nestedValue)];
        }];
    } else {
        [mutableQueryStringComponents addObject:[[AFQueryStringPair alloc] initWithField:key value:value]];
    }
    
    return mutableQueryStringComponents;
}

static NSString * AFJSONStringFromParameters(NSDictionary *parameters) {
    NSError *error = nil;
    NSData *JSONData = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:&error];;
    
    if (!error) {
        return [[NSString alloc] initWithData:JSONData encoding:NSUTF8StringEncoding];
    } else {
        return nil;
    }
}

static NSString * AFPropertyListStringFromParameters(NSDictionary *parameters) {
    NSString *propertyListString = nil;
    NSError *error = nil;
    
    NSData *propertyListData = [NSPropertyListSerialization dataWithPropertyList:parameters format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
    if (!error) {
        propertyListString = [[NSString alloc] initWithData:propertyListData encoding:NSUTF8StringEncoding] ;
    }
    
    return propertyListString;
}

@interface AFHTTPClient ()
@property (readwrite, nonatomic) NSURL *baseURL;
@property (readwrite, nonatomic) NSMutableArray *registeredHTTPOperationClassNames;
@property (readwrite, nonatomic) NSMutableDictionary *defaultHeaders;
@property (readwrite, nonatomic) NSOperationQueue *operationQueue;
#ifdef _SYSTEMCONFIGURATION_H
@property (readwrite, nonatomic, assign) AFNetworkReachabilityRef networkReachability;
@property (readwrite, nonatomic, assign) AFNetworkReachabilityStatus networkReachabilityStatus;
@property (readwrite, nonatomic, copy) AFNetworkReachabilityStatusBlock networkReachabilityStatusBlock;
#endif

#ifdef _SYSTEMCONFIGURATION_H
- (void)startMonitoringNetworkReachability;
- (void)stopMonitoringNetworkReachability;
#endif
@end

@implementation AFHTTPClient
@synthesize baseURL = _baseURL;
@synthesize stringEncoding = _stringEncoding;
@synthesize parameterEncoding = _parameterEncoding;
@synthesize registeredHTTPOperationClassNames = _registeredHTTPOperationClassNames;
@synthesize defaultHeaders = _defaultHeaders;
@synthesize operationQueue = _operationQueue;
#ifdef _SYSTEMCONFIGURATION_H
@synthesize networkReachability = _networkReachability;
@synthesize networkReachabilityStatus = _networkReachabilityStatus;
@synthesize networkReachabilityStatusBlock = _networkReachabilityStatusBlock;
#endif

+ (AFHTTPClient *)clientWithBaseURL:(NSURL *)url {
    return [[self alloc] initWithBaseURL:url];
}

- (id)initWithBaseURL:(NSURL *)url {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    // Ensure terminal slash for baseURL path, so that NSURL +URLWithString:relativeToURL: works as expected
    if ([[url path] length] > 0 && ![[url absoluteString] hasSuffix:@"/"]) {
        url = [url URLByAppendingPathComponent:@""];
    }
    
    self.baseURL = url;
    
    self.stringEncoding = NSUTF8StringEncoding;
    self.parameterEncoding = AFFormURLParameterEncoding;
	
    self.registeredHTTPOperationClassNames = [NSMutableArray array];
    
	self.defaultHeaders = [NSMutableDictionary dictionary];
	
    // Accept-Language HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.4
    NSString *preferredLanguageCodes = [[NSLocale preferredLanguages] componentsJoinedByString:@", "];
    [self setDefaultHeader:@"Accept-Language" value:[NSString stringWithFormat:@"%@, en-us;q=0.8", preferredLanguageCodes]];
    
#if __IPHONE_OS_VERSION_MIN_REQUIRED
    // User-Agent Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.43
    [self setDefaultHeader:@"User-Agent" value:[NSString stringWithFormat:@"%@/%@ (%@; iOS %@; Scale/%0.2f)", [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleExecutableKey] ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleIdentifierKey], (__bridge id)CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey) ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey], [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion], ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] ? [[UIScreen mainScreen] scale] : 1.0f)]];
#elif __MAC_OS_X_VERSION_MIN_REQUIRED
    [self setDefaultHeader:@"User-Agent" value:[NSString stringWithFormat:@"%@/%@ (Mac OS X %@)", [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleExecutableKey] ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleIdentifierKey], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey], [[NSProcessInfo processInfo] operatingSystemVersionString]]];
#endif
    
#ifdef _SYSTEMCONFIGURATION_H
    self.networkReachabilityStatus = AFNetworkReachabilityStatusUnknown;
    [self startMonitoringNetworkReachability];
#endif
    
    self.operationQueue = [[NSOperationQueue alloc] init];
	[self.operationQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
    
    return self;
}

- (void)dealloc {
#ifdef _SYSTEMCONFIGURATION_H
    [self stopMonitoringNetworkReachability];
#endif
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, baseURL: %@, defaultHeaders: %@, registeredOperationClasses: %@, operationQueue: %@>", NSStringFromClass([self class]), self, [self.baseURL absoluteString], self.defaultHeaders, self.registeredHTTPOperationClassNames, self.operationQueue];
}

#pragma mark -

#ifdef _SYSTEMCONFIGURATION_H
static BOOL AFURLHostIsIPAddress(NSURL *url) {
    struct sockaddr_in sa_in;
    struct sockaddr_in6 sa_in6;
    
    return [url host] && (inet_pton(AF_INET, [[url host] UTF8String], &sa_in) == 1 || inet_pton(AF_INET6, [[url host] UTF8String], &sa_in6) == 1);
}

static AFNetworkReachabilityStatus AFNetworkReachabilityStatusForFlags(SCNetworkReachabilityFlags flags) {
    BOOL isReachable = ((flags & kSCNetworkReachabilityFlagsReachable) != 0);
    BOOL needsConnection = ((flags & kSCNetworkReachabilityFlagsConnectionRequired) != 0);
    BOOL isNetworkReachable = (isReachable && !needsConnection);
    
    AFNetworkReachabilityStatus status = AFNetworkReachabilityStatusUnknown;
    if(isNetworkReachable == NO){
        status = AFNetworkReachabilityStatusNotReachable;
    }
#if	TARGET_OS_IPHONE
    else if((flags & kSCNetworkReachabilityFlagsIsWWAN) != 0){
        status = AFNetworkReachabilityStatusReachableViaWWAN;
    }
#endif
    else {
        status = AFNetworkReachabilityStatusReachableViaWiFi;
    }
    
    return status;
}

static void AFNetworkReachabilityCallback(SCNetworkReachabilityRef __unused target, SCNetworkReachabilityFlags flags, void *info) {
    AFNetworkReachabilityStatus status = AFNetworkReachabilityStatusForFlags(flags);
    AFNetworkReachabilityStatusBlock block = (__bridge AFNetworkReachabilityStatusBlock)info;
    if (block) {
        block(status);
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:AFNetworkingReachabilityDidChangeNotification object:nil userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:status] forKey:AFNetworkingReachabilityNotificationStatusItem]];
}

static const void * AFNetworkReachabilityRetainCallback(const void *info) {
    return (__bridge_retained const void *)([(__bridge AFNetworkReachabilityStatusBlock)info copy]);
}

static void AFNetworkReachabilityReleaseCallback(const void *info) {}

- (void)startMonitoringNetworkReachability {
    [self stopMonitoringNetworkReachability];
    
    if (!self.baseURL) {
        return;
    }
    
    self.networkReachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, [[self.baseURL host] UTF8String]);
    
    AFNetworkReachabilityStatusBlock callback = ^(AFNetworkReachabilityStatus status){
        self.networkReachabilityStatus = status;
        if (self.networkReachabilityStatusBlock) {
            self.networkReachabilityStatusBlock(status);
        }
    };
    
    SCNetworkReachabilityContext context = {0, (__bridge void *)callback, AFNetworkReachabilityRetainCallback, AFNetworkReachabilityReleaseCallback, NULL};
    SCNetworkReachabilitySetCallback(self.networkReachability, AFNetworkReachabilityCallback, &context);
    SCNetworkReachabilityScheduleWithRunLoop(self.networkReachability, CFRunLoopGetMain(), (CFStringRef)NSRunLoopCommonModes);
    
    /* Network reachability monitoring does not establish a baseline for IP addresses as it does for hostnames, so if the base URL host is an IP address, the initial reachability callback is manually triggered.
     */
    if (AFURLHostIsIPAddress(self.baseURL)) {
        SCNetworkReachabilityFlags flags;
        SCNetworkReachabilityGetFlags(self.networkReachability, &flags);
        dispatch_async(dispatch_get_main_queue(), ^{
            AFNetworkReachabilityStatus status = AFNetworkReachabilityStatusForFlags(flags);
            callback(status);
        });
    }
}

- (void)stopMonitoringNetworkReachability {
    if (_networkReachability) {
        SCNetworkReachabilityUnscheduleFromRunLoop(_networkReachability, CFRunLoopGetMain(), (CFStringRef)NSRunLoopCommonModes);
        CFRelease(_networkReachability);
        _networkReachability = NULL;
    }
}

- (void)setReachabilityStatusChangeBlock:(void (^)(AFNetworkReachabilityStatus status))block {
    self.networkReachabilityStatusBlock = block;
}
#endif

#pragma mark -

- (BOOL)registerHTTPOperationClass:(Class)operationClass {
    if (![operationClass isSubclassOfClass:[AFHTTPRequestOperation class]]) {
        return NO;
    }
    
    NSString *className = NSStringFromClass(operationClass);
    [self.registeredHTTPOperationClassNames removeObject:className];
    [self.registeredHTTPOperationClassNames insertObject:className atIndex:0];
    
    return YES;
}

- (void)unregisterHTTPOperationClass:(Class)operationClass {
    NSString *className = NSStringFromClass(operationClass);
    [self.registeredHTTPOperationClassNames removeObject:className];
}

#pragma mark -

- (NSString *)defaultValueForHeader:(NSString *)header {
	return [self.defaultHeaders valueForKey:header];
}

- (void)setDefaultHeader:(NSString *)header value:(NSString *)value {
	[self.defaultHeaders setValue:value forKey:header];
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

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters
{
    NSURL *url = [NSURL URLWithString:path relativeToURL:self.baseURL];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:method];
    [request setAllHTTPHeaderFields:self.defaultHeaders];

    if ([method isEqualToString:@"GET"] || [method isEqualToString:@"HEAD"]) {
        [request setHTTPShouldUsePipelining:YES];
    }
	
    if (parameters) {
        if ([method isEqualToString:@"GET"] || [method isEqualToString:@"HEAD"] || [method isEqualToString:@"DELETE"]) {
            url = [NSURL URLWithString:[[url absoluteString] stringByAppendingFormat:[path rangeOfString:@"?"].location == NSNotFound ? @"?%@" : @"&%@", AFQueryStringFromParametersWithEncoding(parameters, self.stringEncoding)]];
            [request setURL:url];
        } else {
            NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(self.stringEncoding));
            switch (self.parameterEncoding) {
                case AFFormURLParameterEncoding:;
                    [request setValue:[NSString stringWithFormat:@"application/x-www-form-urlencoded; charset=%@", charset] forHTTPHeaderField:@"Content-Type"];
                    [request setHTTPBody:[AFQueryStringFromParametersWithEncoding(parameters, self.stringEncoding) dataUsingEncoding:self.stringEncoding]];
                    break;
                case AFJSONParameterEncoding:;
                    [request setValue:[NSString stringWithFormat:@"application/json; charset=%@", charset] forHTTPHeaderField:@"Content-Type"];
                    [request setHTTPBody:[AFJSONStringFromParameters(parameters) dataUsingEncoding:self.stringEncoding]];
                    break;
                case AFPropertyListParameterEncoding:;
                    [request setValue:[NSString stringWithFormat:@"application/x-plist; charset=%@", charset] forHTTPHeaderField:@"Content-Type"];
                    [request setHTTPBody:[AFPropertyListStringFromParameters(parameters) dataUsingEncoding:self.stringEncoding]];
                    break;
            }
        }
    }
    
	return request;
}

- (NSMutableURLRequest *)multipartFormRequestWithMethod:(NSString *)method
                                                   path:(NSString *)path
                                             parameters:(NSDictionary *)parameters
                              constructingBodyWithBlock:(void (^)(id <AFMultipartFormData>formData))block
{
    NSMutableURLRequest *request = [self requestWithMethod:method path:path parameters:nil];
    __block AFMultipartFormData *formData = [[AFMultipartFormData alloc] initWithURLRequest:request stringEncoding:self.stringEncoding];
    
    if (parameters) {
        for (AFQueryStringPair *pair in AFQueryStringPairsFromDictionary(parameters)) {
            NSData *data = nil;
            if ([pair.value isKindOfClass:[NSData class]]) {
                data = pair.value;
            } else {
                data = [[pair.value description] dataUsingEncoding:self.stringEncoding];
            }
            
            if (data) {
                [formData appendPartWithFormData:data name:[pair.field description]];
            }
        }
    }
    
    if (block) {
        block(formData);
    }
    
    return [formData requestByFinalizingMultipartFormData];
}

- (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                                    success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                                    failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    AFHTTPRequestOperation *operation = nil;
    NSString *className = nil;
    NSEnumerator *enumerator = [self.registeredHTTPOperationClassNames reverseObjectEnumerator];
    while (!operation && (className = [enumerator nextObject])) {
        Class op_class = NSClassFromString(className);
        if (op_class && [op_class canProcessRequest:urlRequest]) {
            operation = [(AFHTTPRequestOperation *)[op_class alloc] initWithRequest:urlRequest];
        }
    }
    
    if (!operation) {
        operation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
    }
    
    [operation setCompletionBlockWithSuccess:success failure:failure];
    
    return operation;
}

#pragma mark -

- (void)enqueueHTTPRequestOperation:(AFHTTPRequestOperation *)operation {
    [self.operationQueue addOperation:operation];
}

- (void)cancelAllHTTPOperationsWithMethod:(NSString *)method path:(NSString *)path {
    for (NSOperation *operation in [self.operationQueue operations]) {
        if (![operation isKindOfClass:[AFHTTPRequestOperation class]]) {
            continue;
        }
        
        if ((!method || [method isEqualToString:[[(AFHTTPRequestOperation *)operation request] HTTPMethod]]) && [path isEqualToString:[[[(AFHTTPRequestOperation *)operation request] URL] path]]) {
            [operation cancel];
        }
    }
}

- (void)enqueueBatchOfHTTPRequestOperationsWithRequests:(NSArray *)requests
                                          progressBlock:(void (^)(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations))progressBlock
                                        completionBlock:(void (^)(NSArray *operations))completionBlock
{
    NSMutableArray *mutableOperations = [NSMutableArray array];
    for (NSURLRequest *request in requests) {
        AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:nil failure:nil];
        [mutableOperations addObject:operation];
    }
    
    [self enqueueBatchOfHTTPRequestOperations:mutableOperations progressBlock:progressBlock completionBlock:completionBlock];
}

- (void)enqueueBatchOfHTTPRequestOperations:(NSArray *)operations
                              progressBlock:(void (^)(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations))progressBlock
                            completionBlock:(void (^)(NSArray *operations))completionBlock
{
    __block dispatch_group_t dispatchGroup = dispatch_group_create();
    NSBlockOperation *batchedOperation = [NSBlockOperation blockOperationWithBlock:^{
        dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), ^{
            if (completionBlock) {
                completionBlock(operations);
            }
        });
#if AF_DISPATCH_RETAIN_RELEASE
        dispatch_release(dispatchGroup);
#endif
    }];
    
    for (AFHTTPRequestOperation *operation in operations) {
        AFCompletionBlock originalCompletionBlock = [operation.completionBlock copy];
        operation.completionBlock = ^{
            dispatch_queue_t queue = operation.successCallbackQueue ?: dispatch_get_main_queue();
            dispatch_group_async(dispatchGroup, queue, ^{
                if (originalCompletionBlock) {
                    originalCompletionBlock();
                }
                
                __block NSUInteger numberOfFinishedOperations = 0;
                [operations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    if ([(NSOperation *)obj isFinished]) {
                        numberOfFinishedOperations++;
                    }
                }];
                
                if (progressBlock) {
                    progressBlock(numberOfFinishedOperations, [operations count]);
                }
                
                dispatch_group_leave(dispatchGroup);
            });
        };
        
        dispatch_group_enter(dispatchGroup);
        [batchedOperation addDependency:operation];
        
        [self enqueueHTTPRequestOperation:operation];
    }
    [self.operationQueue addOperation:batchedOperation];
}

#pragma mark -

- (void)getPath:(NSString *)path
     parameters:(NSDictionary *)parameters
        success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
        failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
	NSURLRequest *request = [self requestWithMethod:@"GET" path:path parameters:parameters];
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [self enqueueHTTPRequestOperation:operation];
}

- (void)postPath:(NSString *)path
      parameters:(NSDictionary *)parameters
         success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
	NSURLRequest *request = [self requestWithMethod:@"POST" path:path parameters:parameters];
	AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [self enqueueHTTPRequestOperation:operation];
}

- (void)putPath:(NSString *)path
     parameters:(NSDictionary *)parameters
        success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
        failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
	NSURLRequest *request = [self requestWithMethod:@"PUT" path:path parameters:parameters];
	AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [self enqueueHTTPRequestOperation:operation];
}

- (void)deletePath:(NSString *)path
        parameters:(NSDictionary *)parameters
           success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
           failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
	NSURLRequest *request = [self requestWithMethod:@"DELETE" path:path parameters:parameters];
	AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [self enqueueHTTPRequestOperation:operation];
}

- (void)patchPath:(NSString *)path
       parameters:(NSDictionary *)parameters
          success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
          failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    NSURLRequest *request = [self requestWithMethod:@"PATCH" path:path parameters:parameters];
	AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [self enqueueHTTPRequestOperation:operation];
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    NSURL *baseURL = [aDecoder decodeObjectForKey:@"baseURL"];
    
    self = [self initWithBaseURL:baseURL];
    if (!self) {
        return nil;
    }
    
    self.stringEncoding = [aDecoder decodeIntegerForKey:@"stringEncoding"];
    self.parameterEncoding = [aDecoder decodeIntegerForKey:@"parameterEncoding"];
    self.registeredHTTPOperationClassNames = [aDecoder decodeObjectForKey:@"registeredHTTPOperationClassNames"];
    self.defaultHeaders = [aDecoder decodeObjectForKey:@"defaultHeaders"];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.baseURL forKey:@"baseURL"];
    [aCoder encodeInteger:self.stringEncoding forKey:@"stringEncoding"];
    [aCoder encodeInteger:self.parameterEncoding forKey:@"parameterEncoding"];
    [aCoder encodeObject:self.registeredHTTPOperationClassNames forKey:@"registeredHTTPOperationClassNames"];
    [aCoder encodeObject:self.defaultHeaders forKey:@"defaultHeaders"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    AFHTTPClient *HTTPClient = [[[self class] allocWithZone:zone] initWithBaseURL:self.baseURL];
    
    HTTPClient.stringEncoding = self.stringEncoding;
    HTTPClient.parameterEncoding = self.parameterEncoding;
    HTTPClient.registeredHTTPOperationClassNames = [self.registeredHTTPOperationClassNames copyWithZone:zone];
    HTTPClient.defaultHeaders = [self.defaultHeaders copyWithZone:zone];
#ifdef _SYSTEMCONFIGURATION_H
    HTTPClient.networkReachabilityStatusBlock = self.networkReachabilityStatusBlock;
#endif
    return HTTPClient;
}

@end

#pragma mark -

static NSString * const kAFMultipartTemporaryFileDirectoryName = @"com.alamofire.uploads";

static NSString * AFMultipartTemporaryFileDirectoryPath() {
    static NSString *multipartTemporaryFilePath = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        multipartTemporaryFilePath = [[NSTemporaryDirectory() stringByAppendingPathComponent:kAFMultipartTemporaryFileDirectoryName] copy];
        
        NSError *error = nil;
        if(![[NSFileManager defaultManager] createDirectoryAtPath:multipartTemporaryFilePath withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"Failed to create multipart temporary file directory at %@", multipartTemporaryFilePath);
        }
    });
    
    return multipartTemporaryFilePath;
}

static NSString * const kAFMultipartFormBoundary = @"Boundary+0xAbCdEfGbOuNdArY";

static NSString * const kAFMultipartFormCRLF = @"\r\n";

static inline NSString * AFMultipartFormInitialBoundary() {
    return [NSString stringWithFormat:@"--%@%@", kAFMultipartFormBoundary, kAFMultipartFormCRLF];
}

static inline NSString * AFMultipartFormEncapsulationBoundary() {
    return [NSString stringWithFormat:@"%@--%@%@", kAFMultipartFormCRLF, kAFMultipartFormBoundary, kAFMultipartFormCRLF];
}

static inline NSString * AFMultipartFormFinalBoundary() {
    return [NSString stringWithFormat:@"%@--%@--%@", kAFMultipartFormCRLF, kAFMultipartFormBoundary, kAFMultipartFormCRLF];
}

@interface AFMultipartFormData ()
@property (readwrite, nonatomic) NSMutableURLRequest *request;
@property (readwrite, nonatomic, assign) NSStringEncoding stringEncoding;
@property (readwrite, nonatomic, strong) NSOutputStream *outputStream;
@property (readwrite, nonatomic, copy) NSString *temporaryFilePath;
@end

@implementation AFMultipartFormData
@synthesize request = _request;
@synthesize stringEncoding = _stringEncoding;
@synthesize outputStream = _outputStream;
@synthesize temporaryFilePath = _temporaryFilePath;

- (id)initWithURLRequest:(NSMutableURLRequest *)request
          stringEncoding:(NSStringEncoding)encoding
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.request = request;
    self.stringEncoding = encoding;
    
    self.temporaryFilePath = [AFMultipartTemporaryFileDirectoryPath() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
    self.outputStream = [NSOutputStream outputStreamToFileAtPath:self.temporaryFilePath append:NO];
    
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    [self.outputStream scheduleInRunLoop:runLoop forMode:NSRunLoopCommonModes];
    [self.outputStream open];
    
    return self;
}

- (void)dealloc {
    
    if (_outputStream) {
        [_outputStream close];
    }
    
}

- (NSMutableURLRequest *)requestByFinalizingMultipartFormData {
    // Close the stream and return the original request if no data has been written
    if ([[self.outputStream propertyForKey:NSStreamFileCurrentOffsetKey] integerValue] == 0) {
        [self.outputStream close];
        
        return self.request;
    }
    
    [self appendData:[AFMultipartFormFinalBoundary() dataUsingEncoding:self.stringEncoding]];
    
    [self.request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", kAFMultipartFormBoundary] forHTTPHeaderField:@"Content-Type"];
    [self.request setValue:[[self.outputStream propertyForKey:NSStreamFileCurrentOffsetKey] stringValue] forHTTPHeaderField:@"Content-Length"];
    [self.request setHTTPBodyStream:[NSInputStream inputStreamWithFileAtPath:self.temporaryFilePath]];
    
    [self.outputStream close];
    
    return self.request;
}

#pragma mark - AFMultipartFormData

- (void)appendBoundary {
    if ([[self.outputStream propertyForKey:NSStreamFileCurrentOffsetKey] integerValue] == 0) {
        [self appendString:AFMultipartFormInitialBoundary()];
    } else {
        [self appendString:AFMultipartFormEncapsulationBoundary()];
    }
}

- (void)appendPartWithHeaders:(NSDictionary *)headers
                         body:(NSData *)body
{
    [self appendBoundary];
    
    for (NSString *field in [headers allKeys]) {
        [self appendString:[NSString stringWithFormat:@"%@: %@%@", field, [headers valueForKey:field], kAFMultipartFormCRLF]];
    }
    
    [self appendString:kAFMultipartFormCRLF];
    [self appendData:body];
}

- (void)appendPartWithFormData:(NSData *)data
                          name:(NSString *)name
{
    NSMutableDictionary *mutableHeaders = [NSMutableDictionary dictionary];
    [mutableHeaders setValue:[NSString stringWithFormat:@"form-data; name=\"%@\"", name] forKey:@"Content-Disposition"];
    
    [self appendPartWithHeaders:mutableHeaders body:data];
}

- (void)appendPartWithFileData:(NSData *)data
                          name:(NSString *)name
                      fileName:(NSString *)fileName
                      mimeType:(NSString *)mimeType
{
    NSMutableDictionary *mutableHeaders = [NSMutableDictionary dictionary];
    [mutableHeaders setValue:[NSString stringWithFormat:@"form-data; name=\"%@\"; filename=\"%@\"", name, fileName] forKey:@"Content-Disposition"];
    [mutableHeaders setValue:mimeType forKey:@"Content-Type"];
    
    [self appendPartWithHeaders:mutableHeaders body:data];
}

- (BOOL)appendPartWithFileURL:(NSURL *)fileURL
                         name:(NSString *)name
                        error:(NSError **)error
{
    if (![fileURL isFileURL]) {
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        [userInfo setValue:fileURL forKey:NSURLErrorFailingURLErrorKey];
        [userInfo setValue:NSLocalizedString(@"Expected URL to be a file URL", nil) forKey:NSLocalizedFailureReasonErrorKey];
        if (error != NULL) {
            *error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:userInfo];
        }
        
        return NO;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:fileURL];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    
    NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:error];
    
    if (data && response) {
        [self appendPartWithFileData:data name:name fileName:[response suggestedFilename] mimeType:[response MIMEType]];
        
        return YES;
    } else {
        return NO;
    }
}

- (void)appendString:(NSString *)string {
    [self appendData:[string dataUsingEncoding:self.stringEncoding]];
}

- (void)appendData:(NSData *)data {
    if ([data length] == 0) {
        return;
    }
    
    if ([self.outputStream hasSpaceAvailable]) {
        const uint8_t *dataBuffer = (uint8_t *) [data bytes];
        [self.outputStream write:&dataBuffer[0] maxLength:[data length]];
    }
}

@end
