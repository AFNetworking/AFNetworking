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
#import "AFJSONUtilities.h"

#import <Availability.h>

#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>
#else
#import <CoreServices/CoreServices.h>
#endif

#ifdef _SYSTEMCONFIGURATION_H
#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>
#endif


NSString * const AFNetworkingReachabilityDidChangeNotification = @"com.alamofire.networking.reachability.change";

@interface AFStreamingMultipartFormData : NSObject <AFStreamingMultipartFormData>
- (id)initWithURLRequest:(NSMutableURLRequest *)request 
          stringEncoding:(NSStringEncoding)encoding;

- (NSMutableURLRequest *)requestByFinalizingMultipartFormData;

@end

@interface AFMultipartBodyStream : NSInputStream <NSStreamDelegate>


-(id)initWithStringEncoding:(NSStringEncoding)encoding;
-(BOOL)addFileFromURL:(NSURL *)fileURL name:(NSString *)name error:(NSError **)error;
-(void)addFormData:(NSData *)data name:(NSString *)name;
-(NSUInteger)contentLength;
-(BOOL)empty;

@end

#pragma mark -

#ifdef _SYSTEMCONFIGURATION_H
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
    
    return [[[NSString alloc] initWithData:mutableData encoding:NSASCIIStringEncoding] autorelease];
}

NSString * AFURLEncodedStringFromStringWithEncoding(NSString *string, NSStringEncoding encoding) {
    static NSString * const kAFLegalCharactersToBeEscaped = @"?!@#$^&%*+=,:;'\"`<>()[]{}/\\|~ ";
    
	return [(NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)string, NULL, (CFStringRef)kAFLegalCharactersToBeEscaped, CFStringConvertNSStringEncodingToEncoding(encoding)) autorelease];
}

#pragma mark -

@interface AFQueryStringComponent : NSObject {
@private
    NSString *_key;
    NSString *_value;
}

@property (readwrite, nonatomic, retain) id key;
@property (readwrite, nonatomic, retain) id value;

- (id)initWithKey:(id)key value:(id)value; 
- (NSString *)URLEncodedStringValueWithEncoding:(NSStringEncoding)stringEncoding;

@end

@implementation AFQueryStringComponent 
@synthesize key = _key;
@synthesize value = _value;

- (id)initWithKey:(id)key value:(id)value {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.key = key;
    self.value = value;
    
    return self;
}

- (void)dealloc {
    [_key release];
    [_value release];
    [super dealloc];
}

- (NSString *)URLEncodedStringValueWithEncoding:(NSStringEncoding)stringEncoding {
    return [NSString stringWithFormat:@"%@=%@", self.key, AFURLEncodedStringFromStringWithEncoding([self.value description], stringEncoding)];
}

@end

#pragma mark -

extern NSArray * AFQueryStringComponentsFromKeyAndValue(NSString *key, id value);
extern NSArray * AFQueryStringComponentsFromKeyAndDictionaryValue(NSString *key, NSDictionary *value);
extern NSArray * AFQueryStringComponentsFromKeyAndArrayValue(NSString *key, NSArray *value);

NSString * AFQueryStringFromParametersWithEncoding(NSDictionary *parameters, NSStringEncoding stringEncoding) {
    NSMutableArray *mutableComponents = [NSMutableArray array];
    for (AFQueryStringComponent *component in AFQueryStringComponentsFromKeyAndValue(nil, parameters)) {
        [mutableComponents addObject:[component URLEncodedStringValueWithEncoding:stringEncoding]];
    }
    
    return [mutableComponents componentsJoinedByString:@"&"];
}

NSArray * AFQueryStringComponentsFromKeyAndValue(NSString *key, id value) {
    NSMutableArray *mutableQueryStringComponents = [NSMutableArray array];
    
    if([value isKindOfClass:[NSDictionary class]]) {
        [mutableQueryStringComponents addObjectsFromArray:AFQueryStringComponentsFromKeyAndDictionaryValue(key, value)];
    } else if([value isKindOfClass:[NSArray class]]) {
        [mutableQueryStringComponents addObjectsFromArray:AFQueryStringComponentsFromKeyAndArrayValue(key, value)];
    } else {
        [mutableQueryStringComponents addObject:[[[AFQueryStringComponent alloc] initWithKey:key value:value] autorelease]];
    } 
    
    return mutableQueryStringComponents;
}

NSArray * AFQueryStringComponentsFromKeyAndDictionaryValue(NSString *key, NSDictionary *value){
    NSMutableArray *mutableQueryStringComponents = [NSMutableArray array];
    
    [value enumerateKeysAndObjectsUsingBlock:^(id nestedKey, id nestedValue, BOOL *stop) {
        [mutableQueryStringComponents addObjectsFromArray:AFQueryStringComponentsFromKeyAndValue((key ? [NSString stringWithFormat:@"%@[%@]", key, nestedKey] : nestedKey), nestedValue)];
    }];
    
    return mutableQueryStringComponents;
}

NSArray * AFQueryStringComponentsFromKeyAndArrayValue(NSString *key, NSArray *value) {
    NSMutableArray *mutableQueryStringComponents = [NSMutableArray array];
    
    [value enumerateObjectsUsingBlock:^(id nestedValue, NSUInteger idx, BOOL *stop) {
        [mutableQueryStringComponents addObjectsFromArray:AFQueryStringComponentsFromKeyAndValue([NSString stringWithFormat:@"%@[]", key], nestedValue)];
    }];
    
    return mutableQueryStringComponents;
}

static NSString * AFJSONStringFromParameters(NSDictionary *parameters) {
    NSError *error = nil;
    NSData *JSONData = AFJSONEncode(parameters, &error);
    
    if (!error) {
        return [[[NSString alloc] initWithData:JSONData encoding:NSUTF8StringEncoding] autorelease];
    } else {
        return nil;
    }
}

static NSString * AFPropertyListStringFromParameters(NSDictionary *parameters) {
    NSString *propertyListString = nil;
    NSError *error = nil;
    
    NSData *propertyListData = [NSPropertyListSerialization dataWithPropertyList:parameters format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
    if (!error) {
        propertyListString = [[[NSString alloc] initWithData:propertyListData encoding:NSUTF8StringEncoding] autorelease];
    }
    
    return propertyListString;
}

@interface AFHTTPClient ()
@property (readwrite, nonatomic, retain) NSURL *baseURL;
@property (readwrite, nonatomic, retain) NSMutableArray *registeredHTTPOperationClassNames;
@property (readwrite, nonatomic, retain) NSMutableDictionary *defaultHeaders;
@property (readwrite, nonatomic, retain) NSOperationQueue *operationQueue;
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
    return [[[self alloc] initWithBaseURL:url] autorelease];
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
    
	// Accept-Encoding HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.3
	[self setDefaultHeader:@"Accept-Encoding" value:@"gzip"];
	
	// Accept-Language HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.4
	NSString *preferredLanguageCodes = [[NSLocale preferredLanguages] componentsJoinedByString:@", "];
	[self setDefaultHeader:@"Accept-Language" value:[NSString stringWithFormat:@"%@, en-us;q=0.8", preferredLanguageCodes]];
    
#if __IPHONE_OS_VERSION_MIN_REQUIRED
    // User-Agent Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.43
    [self setDefaultHeader:@"User-Agent" value:[NSString stringWithFormat:@"%@/%@ (%@, %@ %@, %@, Scale/%f)", [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleIdentifierKey], [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey], @"unknown", [[UIDevice currentDevice] systemName], [[UIDevice currentDevice] systemVersion], [[UIDevice currentDevice] model], ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] ? [[UIScreen mainScreen] scale] : 1.0)]];
#elif __MAC_OS_X_VERSION_MIN_REQUIRED
    [self setDefaultHeader:@"User-Agent" value:[NSString stringWithFormat:@"%@/%@ (%@)", [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleIdentifierKey], [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey], @"unknown"]];
#endif
    
#ifdef _SYSTEMCONFIGURATION_H
    self.networkReachabilityStatus = AFNetworkReachabilityStatusUnknown;
    [self startMonitoringNetworkReachability];
#endif
    
    self.operationQueue = [[[NSOperationQueue alloc] init] autorelease];
	[self.operationQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
    
    return self;
}

- (void)dealloc {
#ifdef _SYSTEMCONFIGURATION_H
    [self stopMonitoringNetworkReachability];
    [_networkReachabilityStatusBlock release];
#endif
    
    [_baseURL release];
    [_registeredHTTPOperationClassNames release];
    [_defaultHeaders release];
    [_operationQueue release];
    
    [super dealloc];
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
    AFNetworkReachabilityStatusBlock block = (AFNetworkReachabilityStatusBlock)info;
    if (block) {
        block(status);
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:AFNetworkingReachabilityDidChangeNotification object:[NSNumber numberWithInt:status]];
}

static const void * AFNetworkReachabilityRetainCallback(const void *info) {
    return [(AFNetworkReachabilityStatusBlock)info copy];
}

static void AFNetworkReachabilityReleaseCallback(const void *info) {
    [(AFNetworkReachabilityStatusBlock)info release];
}

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
    
    SCNetworkReachabilityContext context = {0, callback, AFNetworkReachabilityRetainCallback, AFNetworkReachabilityReleaseCallback, NULL};
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
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:url] autorelease];
    [request setHTTPMethod:method];
    [request setAllHTTPHeaderFields:self.defaultHeaders];
	
    if (parameters) {        
        if ([method isEqualToString:@"GET"] || [method isEqualToString:@"HEAD"] || [method isEqualToString:@"DELETE"]) {
            url = [NSURL URLWithString:[[url absoluteString] stringByAppendingFormat:[path rangeOfString:@"?"].location == NSNotFound ? @"?%@" : @"&%@", AFQueryStringFromParametersWithEncoding(parameters, self.stringEncoding)]];
            [request setURL:url];
        } else {
            NSString *charset = (NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(self.stringEncoding));
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
                              constructingBodyWithBlock:(void (^)(id <AFStreamingMultipartFormData>formData))block
{
    NSMutableURLRequest *request = [self requestWithMethod:method path:path parameters:nil];
  
    __block AFStreamingMultipartFormData * formData = [[[AFStreamingMultipartFormData alloc] initWithURLRequest:request stringEncoding:self.stringEncoding] autorelease];
   
//  __block AFMultipartFormData *formData = [[[AFMultipartFormData alloc] initWithURLRequest:request stringEncoding:self.stringEncoding] autorelease];
    
    for (AFQueryStringComponent *component in AFQueryStringComponentsFromKeyAndValue(nil, parameters)) {
        NSData *data = nil;
        if ([component.value isKindOfClass:[NSData class]]) {
            data = component.value;
        } else {
            data = [[component.value description] dataUsingEncoding:self.stringEncoding];
        }
        
        if (data) {
            [formData appendPartWithFormData:data name:[component.key description]];
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
            operation = [[(AFHTTPRequestOperation *)[op_class alloc] initWithRequest:urlRequest] autorelease];
        }
    }
    
    if (!operation) {
        operation = [[[AFHTTPRequestOperation alloc] initWithRequest:urlRequest] autorelease];
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
                                          progressBlock:(void (^)(NSUInteger numberOfCompletedOperations, NSUInteger totalNumberOfOperations))progressBlock 
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
                              progressBlock:(void (^)(NSUInteger numberOfCompletedOperations, NSUInteger totalNumberOfOperations))progressBlock 
                            completionBlock:(void (^)(NSArray *operations))completionBlock
{
    __block dispatch_group_t dispatchGroup = dispatch_group_create();
    NSBlockOperation *batchedOperation = [NSBlockOperation blockOperationWithBlock:^{
        dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), ^{
            if (completionBlock) {
                completionBlock(operations);
            }
        });
        dispatch_release(dispatchGroup);
    }];
    
    NSPredicate *finishedOperationPredicate = [NSPredicate predicateWithFormat:@"isFinished == YES"];
    
    for (AFHTTPRequestOperation *operation in operations) {
        AFCompletionBlock originalCompletionBlock = [[operation.completionBlock copy] autorelease];
        operation.completionBlock = ^{
            dispatch_queue_t queue = operation.successCallbackQueue ? operation.successCallbackQueue : dispatch_get_main_queue();
            dispatch_group_async(dispatchGroup, queue, ^{
                if (originalCompletionBlock) {
                    originalCompletionBlock();
                }
                
                if (progressBlock) {
                    progressBlock([[operations filteredArrayUsingPredicate:finishedOperationPredicate] count], [operations count]);
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
    HTTPClient.registeredHTTPOperationClassNames = [[self.registeredHTTPOperationClassNames copyWithZone:zone] autorelease];
    HTTPClient.defaultHeaders = [[self.defaultHeaders copyWithZone:zone] autorelease];
#ifdef _SYSTEMCONFIGURATION_H
    HTTPClient.networkReachabilityStatusBlock = self.networkReachabilityStatusBlock;
#endif
    return HTTPClient;
}

@end

#pragma mark -

static NSString * const kAFMultipartFormBoundary = @"Boundary+0xAbCdEfGbOuNdArY";

static NSString * const kAFMultipartFormCRLF = @"\r\n";

static NSUInteger const kAFMultipart3GThrottleBytesPerSecond = 81920;

static inline NSString * AFMultipartFormInitialBoundary() {
    return [NSString stringWithFormat:@"--%@%@", kAFMultipartFormBoundary, kAFMultipartFormCRLF];
}

static inline NSString * AFMultipartFormEncapsulationBoundary() {
    return [NSString stringWithFormat:@"%@--%@%@", kAFMultipartFormCRLF, kAFMultipartFormBoundary, kAFMultipartFormCRLF];
}

static inline NSString * AFMultipartFormFinalBoundary() {
    return [NSString stringWithFormat:@"%@--%@--%@", kAFMultipartFormCRLF, kAFMultipartFormBoundary, kAFMultipartFormCRLF];
}

#pragma mark --
#pragma mark AFStreamingMultipartFormData


@interface AFStreamingMultipartFormData () {
  AFMultipartBodyStream * bodyStream;
}

@property (readwrite, nonatomic, retain) NSMutableURLRequest *request;
@property (readwrite, nonatomic, assign) NSStringEncoding stringEncoding;

@end

@implementation AFStreamingMultipartFormData 

@synthesize request = _request;
@synthesize stringEncoding = _stringEncoding;

- (id)initWithURLRequest:(NSMutableURLRequest *)request 
          stringEncoding:(NSStringEncoding)encoding 
{
  self = [super init];
  if (!self) {
    return nil;
  }
  self.request = request;
  self.stringEncoding = encoding;
  bodyStream = [[AFMultipartBodyStream alloc] initWithStringEncoding:encoding];
  return self;
}

- (void)dealloc {
  [bodyStream release];
  [super dealloc];
}

-(void)appendPartWithFormData:(NSData *)data name:(NSString *)name {
  [bodyStream addFormData:data name:name];
}

-(BOOL)appendPartWithFileURL:(NSURL *)fileURL name:(NSString *)name error:(NSError **)error {
  return [bodyStream addFileFromURL:fileURL name:name error:error];
}

- (NSMutableURLRequest *)requestByFinalizingMultipartFormData {
  //return the original request if no data has been added
  if ([bodyStream empty]) {
    return self.request;
  }
  [self.request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", kAFMultipartFormBoundary] forHTTPHeaderField:@"Content-Type"];
  [self.request setValue:[NSString stringWithFormat:@"%d",[bodyStream contentLength]] forHTTPHeaderField:@"Content-Length"];
  [self.request setHTTPBodyStream:bodyStream];
  return self.request;
}

@end

#pragma mark --

@class AFMultipartBodyStreamElementHeader;

@protocol AFMultipartBodyStreamElementProtocol <NSObject>

-(AFMultipartBodyStreamElementHeader *)headerElement;
-(NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len;
-(NSUInteger)contentLength;


@end


#pragma mark --
#pragma mark AFMultipartBodyStreamElementProtocol classes

NSInteger AFReadDataIntoBuffer(NSData * data, uint8_t * buffer, NSUInteger maxLength, NSUInteger * cursorPtr);

@interface AFMultipartBodyStreamElement : NSObject <AFMultipartBodyStreamElementProtocol> {
  NSStringEncoding stringEncoding;
  NSUInteger cursor;
}

-(id)initWithStringEncoding:(NSStringEncoding)encoding;
-(id)initWithName:(NSString *)elementName stringEncoding:(NSStringEncoding)encoding;


@property (retain) NSString * name;

@end

@interface AFMultipartBodyStreamElementHeader : AFMultipartBodyStreamElement

@property (retain) NSData * headerData;

+(AFMultipartBodyStreamElementHeader*)headerFromData:(NSData *)data;

@end

@interface AFMultipartBodyStreamFormData : AFMultipartBodyStreamElement

+(AFMultipartBodyStreamFormData *)elementFromData:(NSData *)data withName:(NSString *)name stringEncoding:(NSStringEncoding)stringEncoding;

@end


@interface AFMultipartBodyStreamFileData : AFMultipartBodyStreamElement

+(AFMultipartBodyStreamFileData *)elementFromFileURL:(NSURL *)fileURL name:(NSString *)name stringEncoding:(NSStringEncoding)encoding error:(NSError **)error;

@end

@interface AFMultipartBodyStreamBoundary : AFMultipartBodyStreamElement

+(AFMultipartBodyStreamBoundary *)boundaryFromString:(NSString *)string withEncoding:(NSStringEncoding)stringEncoding;

@end

#pragma mark --
#pragma mark AFMultipartBodyStreamElements

@interface AFMultipartBodyStreamElements : NSEnumerator {
  NSUInteger elementCursor;
  NSMutableArray * elements;
}

@property NSStringEncoding stringEncoding;

-(AFMultipartBodyStreamElements *)initWithStringEncoding:(NSStringEncoding)encoding;
-(NSUInteger)contentLength;
-(void)appendPartWithFormData:(NSData *)data name:(NSString *)name;
-(BOOL)appendPartWithFileURL:(NSURL *)fileURL name:(NSString *)name error:(NSError **)error;

@end

@implementation AFMultipartBodyStreamElements

@synthesize stringEncoding;

-(AFMultipartBodyStreamElements *)initWithStringEncoding:(NSStringEncoding)encoding {
  self = [super init];
  stringEncoding = encoding;
  elementCursor = -1;
  elements = nil;
  return self;
}

-(id)nextObject {
  if (elementCursor == ([elements count] - 1))
    return nil;
  elementCursor++;
  return [elements objectAtIndex:elementCursor];
}

-(NSArray *)allObjects {
  return elements;
}

-(NSUInteger)contentLength {
  NSUInteger sum = 0;
  for (id<AFMultipartBodyStreamElementProtocol> element in elements) {
    sum = sum + [element contentLength];
  }
  return sum;
}

-(void)appendPartWithFormData:(NSData *)data name:(NSString *)name {
  AFMultipartBodyStreamFormData * element = [AFMultipartBodyStreamFormData elementFromData:data withName:name stringEncoding:stringEncoding];
  [self appendPartWithElement:element];
}

-(BOOL)appendPartWithFileURL:(NSURL *)fileURL name:(NSString *)name error:(NSError **)error {
  AFMultipartBodyStreamFileData * element = [AFMultipartBodyStreamFileData elementFromFileURL:fileURL name:name stringEncoding:stringEncoding error:error];
  if (element == nil)
    return NO;
  [self appendPartWithElement:element];
  return YES;
}

-(void)appendPartWithElement:(AFMultipartBodyStreamElement *)element {
  //init elements with init/final boundaries if necessary
  if (elements == nil)
    elements = [[NSMutableArray arrayWithObjects:
                 [AFMultipartBodyStreamBoundary boundaryFromString:AFMultipartFormInitialBoundary() withEncoding:stringEncoding],
                 [AFMultipartBodyStreamBoundary boundaryFromString:AFMultipartFormFinalBoundary() withEncoding:stringEncoding], 
                 nil] retain];

  
  //append encapsulation boundary if needed
  if ([elements count] > 2) {
    [self insertElementBeforeFinalBoundary:[AFMultipartBodyStreamBoundary boundaryFromString:AFMultipartFormEncapsulationBoundary() withEncoding:stringEncoding]];
  }
  
  AFMultipartBodyStreamElementHeader * header = [element headerElement];
  [self insertElementBeforeFinalBoundary:header];  
  [self insertElementBeforeFinalBoundary:element];
}

-(void)insertElementBeforeFinalBoundary:(AFMultipartBodyStreamElement *)element {
  [elements insertObject:element atIndex:[elements count]-1];
}

-(void)dealloc {
  [elements release];
  [super dealloc];
}

@end

NSInteger AFReadDataIntoBuffer(NSData * data, uint8_t * buffer, NSUInteger maxLength, NSUInteger * cursorPtr) {
  NSInteger bytesAvailable = [data length] - *cursorPtr;
  if (maxLength > bytesAvailable) {
    [data getBytes:buffer range:NSMakeRange(*cursorPtr, bytesAvailable)];
    *cursorPtr += bytesAvailable;
    return bytesAvailable;
  } else {
    [data getBytes:buffer range:NSMakeRange(*cursorPtr, maxLength)];
    *cursorPtr += maxLength;
    return maxLength;
  }
}

#pragma mark --
#pragma mark AFMultipartBodyStreamElementProtocol classes

@implementation AFMultipartBodyStreamElement 

@synthesize name;

-(id)initWithName:(NSString *)elementName stringEncoding:(NSStringEncoding)encoding {
  self = [self initWithStringEncoding:encoding];
  self.name = elementName;
  return self;
}

-(id)initWithStringEncoding:(NSStringEncoding)encoding {
  self = [super init];
  assert(encoding != 0);
  stringEncoding = encoding;
  cursor = 0;
  return self;
}

-(NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len {
  assert(false);
}

-(NSUInteger)contentLength {
  assert(false);
}

-(AFMultipartBodyStreamElementHeader *)headerElement {
  assert(false);
}

-(void)dealloc {
  [name release];
  [super dealloc];
}

@end

@implementation AFMultipartBodyStreamElementHeader

@synthesize headerData;

+(AFMultipartBodyStreamElementHeader *)headerFromData:(NSData *)data {
  AFMultipartBodyStreamElementHeader * header = [[[[self class] alloc] init] autorelease];
  header.headerData = data;
  return header;
}

+(NSString *)stringForHeadersDict:(NSDictionary *)headers {
  NSMutableString * headerString = [NSMutableString string];
  for (NSString *field in [headers allKeys]) {
    [headerString appendString:[NSString stringWithFormat:@"%@: %@%@", field, [headers valueForKey:field], kAFMultipartFormCRLF]];
  }
  return [NSString stringWithString:headerString];
}

+(NSData *)dataForHeadersDict:(NSDictionary *)headersDict stringEncoding:(NSStringEncoding)stringEncoding {
  NSMutableString * headerString = [NSMutableString string]; 
  [headerString appendString:[[self class] stringForHeadersDict:headersDict]];
  [headerString appendString:kAFMultipartFormCRLF];
  
  return [headerString dataUsingEncoding:stringEncoding];
}

-(NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len {
  return AFReadDataIntoBuffer(headerData, buffer, len, &cursor);
}

-(NSUInteger)contentLength {
  return [headerData length];
}

-(void)dealloc {
  [headerData release];
  [super dealloc];
}

@end


@implementation AFMultipartBodyStreamFormData {
  NSData * formData;
}

+(AFMultipartBodyStreamFormData *)elementFromData:(NSData *)data withName:(NSString *)name stringEncoding:(NSStringEncoding)stringEncoding {
  AFMultipartBodyStreamFormData * element = [[[[self class] alloc] initWithData:data name:name stringEncoding:stringEncoding] autorelease];
  return element;
}

-(id)initWithData:(NSData *)data name:(NSString *)elementName stringEncoding:(NSStringEncoding)encoding {
  self = [self initWithName:elementName stringEncoding:encoding];
  formData = [data retain];
  return self;
}

-(NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len {
  return AFReadDataIntoBuffer(formData, buffer, len, &cursor);
}

-(NSUInteger)contentLength {
  return [formData length];
}

-(AFMultipartBodyStreamElementHeader *)headerElement {
  NSData * headerData = [AFMultipartBodyStreamElementHeader dataForHeadersDict:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"form-data; name=\"%@\"", self.name] forKey:@"Content-Disposition"] 
                                          stringEncoding:stringEncoding];
  return [AFMultipartBodyStreamElementHeader headerFromData:headerData];
}

-(void)dealloc {
  [formData release];
  [super dealloc];
}

@end


@implementation AFMultipartBodyStreamFileData {
  NSURL * url;
  NSInputStream * fileStream;
}

+(AFMultipartBodyStreamFileData *)elementFromFileURL:(NSURL *)fileURL name:(NSString *)name stringEncoding:(NSStringEncoding)encoding error:(NSError **)error {
  return [[[[self class] alloc] initWithFileURL:fileURL name:name stringEncoding:encoding error:error] autorelease];
}

-(id)initWithFileURL:(NSURL *)fileURL name:(NSString *)name stringEncoding:(NSStringEncoding)encoding error:(NSError **)error {  
  NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
  [userInfo setValue:fileURL forKey:NSURLErrorFailingURLErrorKey];
  
  if (![fileURL isFileURL]) {
    [userInfo setValue:NSLocalizedString(@"Expected URL to be a file URL", nil) forKey:NSLocalizedFailureReasonErrorKey];
    if (error != NULL) {
      *error = [[[NSError alloc] initWithDomain:AFNetworkingErrorDomain code:NSURLErrorBadURL userInfo:userInfo] autorelease];  
    }
    return nil;
  }
  
  if ([fileURL checkResourceIsReachableAndReturnError:error] == NO) {
    [userInfo setValue:NSLocalizedString(@"File URL not reachable.", nil) forKey:NSLocalizedFailureReasonErrorKey];
    if (error != NULL) {
      *error = [[[NSError alloc] initWithDomain:AFNetworkingErrorDomain code:NSURLErrorBadURL userInfo:userInfo] autorelease];  
    }
    
    return nil;
  }

  self = [self initWithName:name stringEncoding:encoding];
  url = [fileURL retain];
  fileStream = nil;
  return self;
}

-(NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len {
  if (fileStream == nil) {
    fileStream = [[NSInputStream inputStreamWithURL:url] retain];
    [fileStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [fileStream open];
  }
  
  NSInteger bytesRead = [fileStream read:buffer maxLength:len];      
  if (bytesRead == 0) {
    [fileStream close];
    [fileStream release];
    fileStream = nil;
  }
  return bytesRead;
}

-(NSUInteger)contentLength {
  NSError * error;
  NSDictionary * fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[url path] error:&error];
  return [[fileAttributes objectForKey:NSFileSize] longValue];
}

-(AFMultipartBodyStreamElementHeader *)headerElement {
  NSString * fileName = [[url pathComponents] objectAtIndex:([[url pathComponents] count] - 1)];
  NSMutableDictionary * mutableHeaders = [NSMutableDictionary dictionary];
  [mutableHeaders setValue:[NSString stringWithFormat:@"form-data; name=\"%@\"; filename=\"%@\"", self.name, fileName] forKey:@"Content-Disposition"];
  CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)[url pathExtension], NULL);
  NSString * MIMEType = [(NSString*) UTTypeCopyPreferredTagWithClass (UTI, kUTTagClassMIMEType) autorelease];
  CFRelease(UTI);
  [mutableHeaders setValue:MIMEType forKey:@"Content-Type"];
  
  NSData * headerData = [AFMultipartBodyStreamElementHeader dataForHeadersDict:mutableHeaders stringEncoding:stringEncoding];
  return [AFMultipartBodyStreamElementHeader headerFromData:headerData];
}

-(void)dealloc {
  [url release];
  [super dealloc];
}

@end

@implementation AFMultipartBodyStreamBoundary {
  NSData * boundaryData;
}

+(AFMultipartBodyStreamBoundary *)boundaryFromString:(NSString *)string withEncoding:(NSStringEncoding)stringEncoding {
  return [[[[self class] alloc] initWithBoundaryString:string stringEncoding:stringEncoding] autorelease];
}

-(id)init {
  self = [super init];
  boundaryData = nil;
  return self;
}

-(id)initWithBoundaryString:(NSString *)boundaryString stringEncoding:(NSStringEncoding)encoding {
  self = [self initWithStringEncoding:encoding];
  boundaryData = [[boundaryString dataUsingEncoding:stringEncoding] retain];
  return self;
}

-(NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len {
  assert(boundaryData != nil);
  return AFReadDataIntoBuffer(boundaryData, buffer, len, &cursor);
}

-(NSUInteger)contentLength {
  return [boundaryData length];
}

-(void)dealloc {
  [boundaryData release];
  [super dealloc];
}

@end

#pragma mark --
#pragma mark AFMultipartBodyStream

@interface AFMultipartBodyStream () {
  NSStringEncoding stringEncoding;
  AFMultipartBodyStreamElements * elements;
  AFMultipartBodyStreamElement * currentElement;
  NSDate * lastReadAt;
  NSInteger lastBytesRead;
  
  NSStreamStatus streamStatus;
  id <NSStreamDelegate> delegate; 
}

@end

@implementation AFMultipartBodyStream


-(id)init {
  self = [super init];
  stringEncoding = NSUTF8StringEncoding;
  streamStatus = NSStreamStatusNotOpen;
  elements = [[AFMultipartBodyStreamElements alloc] initWithStringEncoding:stringEncoding];
  currentElement = NULL;
  lastReadAt = NULL;
  lastBytesRead = 0;
  return self;
}

-(id)initWithStringEncoding:(NSStringEncoding)encoding {
  self = [self init];
  if (encoding == 0)
    encoding = NSUTF8StringEncoding;
  stringEncoding = encoding;
  elements.stringEncoding = encoding;
  return self;
}

-(void)dealloc {
  [elements release];
  [super dealloc];
}

-(BOOL)addFileFromURL:(NSURL *)fileURL name:(NSString *)name error:(NSError **)error {
  assert([self streamStatus] == NSStreamStatusNotOpen);
  return [elements appendPartWithFileURL:fileURL name:name error:error];
}

-(void)addFormData:(NSData *)data name:(NSString *)name {
  assert([self streamStatus] == NSStreamStatusNotOpen);
  return [elements appendPartWithFormData:data name:name];
}

-(NSUInteger)contentLength {
  return [elements contentLength];
}

-(BOOL)empty {
  return [[elements allObjects] count] == 0;
}

-(BOOL)throttle3G {
  return NO;
}

#pragma mark - NSStream subclass overrides

-(void)open {
  streamStatus = NSStreamStatusOpen;
}

-(void)close {
  streamStatus = NSStreamStatusClosed;
}

- (id <NSStreamDelegate> )delegate {
	return delegate;
}

- (void)setDelegate:(id<NSStreamDelegate>)aDelegate {
	if (aDelegate == nil) {
		delegate = self;
	}
	else {
		delegate = aDelegate;
	}
}

- (void)scheduleInRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode {
}

- (void)removeFromRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode {
}

- (id)propertyForKey:(NSString *)key {
  return nil;
}

- (BOOL)setProperty:(id)property forKey:(NSString *)key {
  return NO;
}


- (NSStreamStatus)streamStatus {
  return streamStatus;
}

- (NSError *)streamError {
  return nil;
}

#pragma mark - NSInputStream subclass overrides

-(NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len {
  if ([self streamStatus] == NSStreamStatusClosed) {
    return 0;    
  }
  assert ([self streamStatus] == NSStreamStatusOpen);
  
  if (currentElement == NULL) {
    currentElement = [elements nextObject];
  }
  
  NSInteger bytesRead = [currentElement read:buffer maxLength:len];
  
  if (bytesRead == 0) {
    currentElement = [elements nextObject];
  }
  
  if (currentElement != nil && bytesRead < len) {
    //recurse to fill out the buffer. the main reason we do this
    //is because we might have read zero bytes above if we reached
    // the end of one element, but if we return zero below, it means 
    //we're ready to close, which we're not.
    bytesRead += [self read:buffer+bytesRead maxLength:len-bytesRead];
  } else {
    if (lastReadAt) {
      if ([self throttle3G]) {
        NSTimeInterval minInterval = (NSTimeInterval)lastBytesRead / kAFMultipart3GThrottleBytesPerSecond;
        NSTimeInterval elapsedInterval = [[NSDate date] timeIntervalSinceDate:lastReadAt];
        if (elapsedInterval < minInterval) {
          [NSThread sleepForTimeInterval:(minInterval - elapsedInterval)];
        }
      }
      [lastReadAt release];
    }
    lastReadAt = [[NSDate date] retain];
  }
  
  lastBytesRead = bytesRead;  
  return bytesRead;
}

-(BOOL)hasBytesAvailable {
  if ([self streamStatus] != NSStreamStatusOpen) {
    return NO;
  } else {
    return YES;
  }
}

-(BOOL)getBuffer:(uint8_t **)buffer length:(NSUInteger *)len {
  return NO;
}

#pragma mark - Undocumented CFReadStream bridged methods

- (void)_scheduleInCFRunLoop:(CFRunLoopRef)aRunLoop forMode:(CFStringRef)aMode {
}

- (BOOL)_setCFClientFlags:(CFOptionFlags)inFlags
                 callback:(CFReadStreamClientCallBack)inCallback
                  context:(CFStreamClientContext *)inContext {
  return NO;
}

- (void)_unscheduleFromCFRunLoop:(CFRunLoopRef)aRunLoop forMode:(CFStringRef)aMode {
}


@end


