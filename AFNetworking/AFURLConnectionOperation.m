// AFURLConnectionOperation.m
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

#import "AFURLConnectionOperation.h"

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
#import <UIKit/UIKit.h>
#endif

#if !__has_feature(objc_arc)
#error AFNetworking must be built with ARC.
// You can turn on ARC for only AFNetworking files by adding -fobjc-arc to the build phase for each of its files.
#endif

typedef enum {
    AFOperationPausedState      = -1,
    AFOperationReadyState       = 1,
    AFOperationExecutingState   = 2,
    AFOperationFinishedState    = 3,
} _AFOperationState;

typedef signed short AFOperationState;

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
typedef UIBackgroundTaskIdentifier AFBackgroundTaskIdentifier;
#else
typedef id AFBackgroundTaskIdentifier;
#endif

static NSString * const kAFNetworkingLockName = @"com.alamofire.networking.operation.lock";

NSString * const AFNetworkingErrorDomain = @"AFNetworkingErrorDomain";
NSString * const AFNetworkingOperationFailingURLRequestErrorKey = @"AFNetworkingOperationFailingURLRequestErrorKey";
NSString * const AFNetworkingOperationFailingURLResponseErrorKey = @"AFNetworkingOperationFailingURLResponseErrorKey";

NSString * const AFNetworkingOperationDidStartNotification = @"com.alamofire.networking.operation.start";
NSString * const AFNetworkingOperationDidFinishNotification = @"com.alamofire.networking.operation.finish";

typedef void (^AFURLConnectionOperationProgressBlock)(NSUInteger bytes, long long totalBytes, long long totalBytesExpected);
#ifndef _AFNETWORKING_PIN_SSL_CERTIFICATES_
typedef BOOL (^AFURLConnectionOperationAuthenticationAgainstProtectionSpaceBlock)(NSURLConnection *connection, NSURLProtectionSpace *protectionSpace);
#endif
typedef void (^AFURLConnectionOperationAuthenticationChallengeBlock)(NSURLConnection *connection, NSURLAuthenticationChallenge *challenge);
typedef NSCachedURLResponse * (^AFURLConnectionOperationCacheResponseBlock)(NSURLConnection *connection, NSCachedURLResponse *cachedResponse);
typedef NSURLRequest * (^AFURLConnectionOperationRedirectResponseBlock)(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *redirectResponse);

static inline NSString * AFKeyPathFromOperationState(AFOperationState state) {
    switch (state) {
        case AFOperationReadyState:
            return @"isReady";
        case AFOperationExecutingState:
            return @"isExecuting";
        case AFOperationFinishedState:
            return @"isFinished";
        case AFOperationPausedState:
            return @"isPaused";
        default:
            return @"state";
    }
}

static inline BOOL AFStateTransitionIsValid(AFOperationState fromState, AFOperationState toState, BOOL isCancelled) {
    switch (fromState) {
        case AFOperationReadyState:
            switch (toState) {
                case AFOperationPausedState:
                case AFOperationExecutingState:
                    return YES;
                case AFOperationFinishedState:
                    return isCancelled;
                default:
                    return NO;
            }
        case AFOperationExecutingState:
            switch (toState) {
                case AFOperationPausedState:
                case AFOperationFinishedState:
                    return YES;
                default:
                    return NO;
            }
        case AFOperationFinishedState:
            return NO;
        case AFOperationPausedState:
            return toState == AFOperationReadyState;
        default:
            return YES;
    }
}

#if !defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
static NSData *AFSecKeyGetData(SecKeyRef key) {
    CFDataRef data = NULL;
    
    OSStatus status = SecItemExport(key, kSecFormatUnknown, kSecItemPemArmour, NULL, &data);
    NSCAssert(status == errSecSuccess, @"SecItemExport error: %ld", (long int)status);
    NSCParameterAssert(data);
    
    return (__bridge_transfer NSData *)data;
}
#endif

static BOOL AFSecKeyIsEqualToKey(SecKeyRef key1, SecKeyRef key2) {
#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
    return [(__bridge id)key1 isEqual:(__bridge id)key2];
#else
    return [AFSecKeyGetData(key1) isEqual:AFSecKeyGetData(key2)];
#endif
}

@interface AFURLConnectionOperation ()
@property (readwrite, nonatomic, assign) AFOperationState state;
@property (readwrite, nonatomic, assign, getter = isCancelled) BOOL cancelled;
@property (readwrite, nonatomic, strong) NSRecursiveLock *lock;
@property (readwrite, nonatomic, strong) NSURLConnection *connection;
@property (readwrite, nonatomic, strong) NSURLRequest *request;
@property (readwrite, nonatomic, strong) NSURLResponse *response;
@property (readwrite, nonatomic, strong) NSError *error;
@property (readwrite, nonatomic, strong) NSData *responseData;
@property (readwrite, nonatomic, copy) NSString *responseString;
@property (readwrite, nonatomic, assign) NSStringEncoding responseStringEncoding;
@property (readwrite, nonatomic, assign) long long totalBytesRead;
@property (readwrite, nonatomic, assign) AFBackgroundTaskIdentifier backgroundTaskIdentifier;
@property (readwrite, nonatomic, copy) AFURLConnectionOperationProgressBlock uploadProgress;
@property (readwrite, nonatomic, copy) AFURLConnectionOperationProgressBlock downloadProgress;
#ifndef _AFNETWORKING_PIN_SSL_CERTIFICATES_
@property (readwrite, nonatomic, copy) AFURLConnectionOperationAuthenticationAgainstProtectionSpaceBlock authenticationAgainstProtectionSpace;
#endif
@property (readwrite, nonatomic, copy) AFURLConnectionOperationAuthenticationChallengeBlock authenticationChallenge;
@property (readwrite, nonatomic, copy) AFURLConnectionOperationCacheResponseBlock cacheResponse;
@property (readwrite, nonatomic, copy) AFURLConnectionOperationRedirectResponseBlock redirectResponse;

- (void)operationDidStart;
- (void)finish;
- (void)cancelConnection;
@end

@implementation AFURLConnectionOperation
@synthesize state = _state;
@synthesize cancelled = _cancelled;
@synthesize connection = _connection;
@synthesize runLoopModes = _runLoopModes;
@synthesize request = _request;
@synthesize response = _response;
@synthesize error = _error;
@synthesize allowsInvalidSSLCertificate = _allowsInvalidSSLCertificate;
@synthesize responseData = _responseData;
@synthesize responseString = _responseString;
@synthesize responseStringEncoding = _responseStringEncoding;
@synthesize totalBytesRead = _totalBytesRead;
@dynamic inputStream;
@synthesize outputStream = _outputStream;
@synthesize credential = _credential;
#ifdef _AFNETWORKING_PIN_SSL_CERTIFICATES_
@synthesize SSLPinningMode = _SSLPinningMode;
#endif
@synthesize shouldUseCredentialStorage = _shouldUseCredentialStorage;
@synthesize userInfo = _userInfo;
@synthesize backgroundTaskIdentifier = _backgroundTaskIdentifier;
@synthesize uploadProgress = _uploadProgress;
@synthesize downloadProgress = _downloadProgress;
@synthesize authenticationChallenge = _authenticationChallenge;
#ifndef _AFNETWORKING_PIN_SSL_CERTIFICATES_
@synthesize authenticationAgainstProtectionSpace = _authenticationAgainstProtectionSpace;
#endif
@synthesize cacheResponse = _cacheResponse;
@synthesize redirectResponse = _redirectResponse;
@synthesize lock = _lock;

+ (void) __attribute__((noreturn)) networkRequestThreadEntryPoint:(id)__unused object {
    do {
        @autoreleasepool {
            [[NSThread currentThread] setName:@"AFNetworking"];
            [[NSRunLoop currentRunLoop] run];
        }
    } while (YES);
}

+ (NSThread *)networkRequestThread {
    static NSThread *_networkRequestThread = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _networkRequestThread = [[NSThread alloc] initWithTarget:self selector:@selector(networkRequestThreadEntryPoint:) object:nil];
        [_networkRequestThread start];
    });
    
    return _networkRequestThread;
}

#ifdef _AFNETWORKING_PIN_SSL_CERTIFICATES_
+ (NSArray *)pinnedCertificates {
    static NSArray *_pinnedCertificates = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        NSArray *paths = [bundle pathsForResourcesOfType:@"cer" inDirectory:@"."];
        
        NSMutableArray *certificates = [NSMutableArray arrayWithCapacity:[paths count]];
        for (NSString *path in paths) {
            NSData *certificateData = [NSData dataWithContentsOfFile:path];
            [certificates addObject:certificateData];
        }
        
        _pinnedCertificates = [[NSArray alloc] initWithArray:certificates];
    });
    
    return _pinnedCertificates;
}

+ (NSArray *)pinnedPublicKeys {
    static NSArray *_pinnedPublicKeys = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *pinnedCertificates = [self pinnedCertificates];
        NSMutableArray *publicKeys = [NSMutableArray arrayWithCapacity:[pinnedCertificates count]];
        
        for (NSData *data in pinnedCertificates) {
            SecCertificateRef allowedCertificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)data);
            NSParameterAssert(allowedCertificate);
            
            SecCertificateRef allowedCertificates[] = {allowedCertificate};
            CFArrayRef certificates = CFArrayCreate(NULL, (const void **)allowedCertificates, 1, NULL);
            
            SecPolicyRef policy = SecPolicyCreateBasicX509();
            SecTrustRef allowedTrust = NULL;
            OSStatus status = SecTrustCreateWithCertificates(certificates, policy, &allowedTrust);
            NSAssert(status == errSecSuccess, @"SecTrustCreateWithCertificates error: %ld", (long int)status);
            
            SecTrustResultType result = 0;
            status = SecTrustEvaluate(allowedTrust, &result);
            NSAssert(status == errSecSuccess, @"SecTrustEvaluate error: %ld", (long int)status);
            
            SecKeyRef allowedPublicKey = SecTrustCopyPublicKey(allowedTrust);            
            NSParameterAssert(allowedPublicKey);
            [publicKeys addObject:(__bridge_transfer id)allowedPublicKey];
            
            CFRelease(allowedTrust);
            CFRelease(policy);
            CFRelease(certificates);
            CFRelease(allowedCertificate);
        }
        
        _pinnedPublicKeys = [[NSArray alloc] initWithArray:publicKeys];
    });
    
    return _pinnedPublicKeys;
}
#endif

- (id)initWithRequest:(NSURLRequest *)urlRequest {
    NSParameterAssert(urlRequest);

    self = [super init];
    if (!self) {
		return nil;
    }
    
    self.lock = [[NSRecursiveLock alloc] init];
    self.lock.name = kAFNetworkingLockName;
    
    self.runLoopModes = [NSSet setWithObject:NSRunLoopCommonModes];
    
    self.request = urlRequest;
    
    self.shouldUseCredentialStorage = YES;

    // #ifdef included for backwards-compatibility 
#ifdef _AFNETWORKING_ALLOW_INVALID_SSL_CERTIFICATES_
    self.allowsInvalidSSLCertificate = YES;
#endif

    self.state = AFOperationReadyState;

    return self;
}

- (void)dealloc {
    if (_outputStream) {
        [_outputStream close];
        _outputStream = nil;
    }
    
#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
    if (_backgroundTaskIdentifier) {
        [[UIApplication sharedApplication] endBackgroundTask:_backgroundTaskIdentifier];
        _backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    }
#endif
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, state: %@, cancelled: %@ request: %@, response: %@>", NSStringFromClass([self class]), self, AFKeyPathFromOperationState(self.state), ([self isCancelled] ? @"YES" : @"NO"), self.request, self.response];
}

- (void)setCompletionBlock:(void (^)(void))block {
    [self.lock lock];
    if (!block) {
        [super setCompletionBlock:nil];
    } else {
        __weak __typeof(&*self)weakSelf = self;
        [super setCompletionBlock:^ {
            __strong __typeof(&*weakSelf)strongSelf = weakSelf;
            
            block();
            [strongSelf setCompletionBlock:nil];
        }];
    }
    [self.lock unlock];
}

- (NSInputStream *)inputStream {
    return self.request.HTTPBodyStream;
}

- (void)setInputStream:(NSInputStream *)inputStream {
    [self willChangeValueForKey:@"inputStream"];
    NSMutableURLRequest *mutableRequest = [self.request mutableCopy];
    mutableRequest.HTTPBodyStream = inputStream;
    self.request = mutableRequest;
    [self didChangeValueForKey:@"inputStream"];
}

- (NSOutputStream *)outputStream {
    if (!_outputStream) {
        self.outputStream = [NSOutputStream outputStreamToMemory];
    }

    return _outputStream;
}

- (void)setOutputStream:(NSOutputStream *)outputStream {
    [self.lock lock];
    if (outputStream != _outputStream) {
        [self willChangeValueForKey:@"outputStream"];
        if (_outputStream) {
            [_outputStream close];
        }
        _outputStream = outputStream;
        [self didChangeValueForKey:@"outputStream"];
    }
    [self.lock unlock];
}

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
- (void)setShouldExecuteAsBackgroundTaskWithExpirationHandler:(void (^)(void))handler {
    [self.lock lock];
    if (!self.backgroundTaskIdentifier) {
        UIApplication *application = [UIApplication sharedApplication];
        __weak __typeof(&*self)weakSelf = self;
        self.backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^{
            __strong __typeof(&*weakSelf)strongSelf = weakSelf;
            
            if (handler) {
                handler();
            }
            
            if (strongSelf) {
                [strongSelf cancel];
                
                [application endBackgroundTask:strongSelf.backgroundTaskIdentifier];
                strongSelf.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
            }
        }];
    }
    [self.lock unlock];
}
#endif

- (void)setUploadProgressBlock:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))block {
    self.uploadProgress = block;
}

- (void)setDownloadProgressBlock:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))block {
    self.downloadProgress = block;
}

#ifdef _AFNETWORKING_PIN_SSL_CERTIFICATES_

- (void)setWillSendRequestForAuthenticationChallengeBlock:(void (^)(NSURLConnection *connection, NSURLAuthenticationChallenge *challenge))block {
    self.authenticationChallenge = block;
}

#else

- (void)setAuthenticationAgainstProtectionSpaceBlock:(BOOL (^)(NSURLConnection *, NSURLProtectionSpace *))block {
    self.authenticationAgainstProtectionSpace = block;
}

- (void)setAuthenticationChallengeBlock:(void (^)(NSURLConnection *connection, NSURLAuthenticationChallenge *challenge))block {
    self.authenticationChallenge = block;
}

#endif

- (void)setCacheResponseBlock:(NSCachedURLResponse * (^)(NSURLConnection *connection, NSCachedURLResponse *cachedResponse))block {
    self.cacheResponse = block;
}

- (void)setRedirectResponseBlock:(NSURLRequest * (^)(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *redirectResponse))block {
    self.redirectResponse = block;
}

- (void)setState:(AFOperationState)state {
    if (!AFStateTransitionIsValid(self.state, state, [self isCancelled])) {
        return;
    }
    
    [self.lock lock];
    NSString *oldStateKey = AFKeyPathFromOperationState(self.state);
    NSString *newStateKey = AFKeyPathFromOperationState(state);
    
    [self willChangeValueForKey:newStateKey];
    [self willChangeValueForKey:oldStateKey];
    _state = state;
    [self didChangeValueForKey:oldStateKey];
    [self didChangeValueForKey:newStateKey];
    [self.lock unlock];
}

- (NSString *)responseString {
    [self.lock lock];
    if (!_responseString && self.response && self.responseData) {
        self.responseString = [[NSString alloc] initWithData:self.responseData encoding:self.responseStringEncoding];
    }
    [self.lock unlock];
    
    return _responseString;
}

- (NSStringEncoding)responseStringEncoding {
    [self.lock lock];
    if (!_responseStringEncoding && self.response) {
        NSStringEncoding stringEncoding = NSUTF8StringEncoding;
        if (self.response.textEncodingName) {
            CFStringEncoding IANAEncoding = CFStringConvertIANACharSetNameToEncoding((__bridge CFStringRef)self.response.textEncodingName);
            if (IANAEncoding != kCFStringEncodingInvalidId) {
                stringEncoding = CFStringConvertEncodingToNSStringEncoding(IANAEncoding);
            }
        }
        
        self.responseStringEncoding = stringEncoding;
    }
    [self.lock unlock];
    
    return _responseStringEncoding;
}

- (void)pause {
    if ([self isPaused] || [self isFinished] || [self isCancelled]) {
        return;
    }
    
    [self.lock lock];
    
    if ([self isExecuting]) {
        [self.connection performSelector:@selector(cancel) onThread:[[self class] networkRequestThread] withObject:nil waitUntilDone:NO modes:[self.runLoopModes allObjects]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
            [notificationCenter postNotificationName:AFNetworkingOperationDidFinishNotification object:self];
        });
    }
    
    self.state = AFOperationPausedState;
    
    [self.lock unlock];
}

- (BOOL)isPaused {
    return self.state == AFOperationPausedState;
}

- (void)resume {
    if (![self isPaused]) {
        return;
    }
    
    [self.lock lock];
    self.state = AFOperationReadyState;
    
    [self start];
    [self.lock unlock];
}

#pragma mark - NSOperation

- (BOOL)isReady {
    return self.state == AFOperationReadyState && [super isReady];
}

- (BOOL)isExecuting {
    return self.state == AFOperationExecutingState;
}

- (BOOL)isFinished {
    return self.state == AFOperationFinishedState;
}

- (BOOL)isConcurrent {
    return YES;
}

- (void)start {
    [self.lock lock];
    if ([self isReady]) {
        self.state = AFOperationExecutingState;
        
        [self performSelector:@selector(operationDidStart) onThread:[[self class] networkRequestThread] withObject:nil waitUntilDone:NO modes:[self.runLoopModes allObjects]];
    }
    [self.lock unlock];
}

- (void)operationDidStart {
    [self.lock lock];
    if (! [self isCancelled]) {
        self.connection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO];
        
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        for (NSString *runLoopMode in self.runLoopModes) {
            [self.connection scheduleInRunLoop:runLoop forMode:runLoopMode];
            [self.outputStream scheduleInRunLoop:runLoop forMode:runLoopMode];
        }
        
        [self.connection start];
    }
    [self.lock unlock];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:AFNetworkingOperationDidStartNotification object:self];
    });
    
    if ([self isCancelled]) {
        [self finish];
    }
}

- (void)finish {
    self.state = AFOperationFinishedState;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:AFNetworkingOperationDidFinishNotification object:self];
    });
}

- (void)cancel {
    [self.lock lock];
    if (![self isFinished] && ![self isCancelled]) {
        [self willChangeValueForKey:@"isCancelled"];
        _cancelled = YES;
        [super cancel];
        [self didChangeValueForKey:@"isCancelled"];
        
        // Cancel the connection on the thread it runs on to prevent race conditions
        [self performSelector:@selector(cancelConnection) onThread:[[self class] networkRequestThread] withObject:nil waitUntilDone:NO modes:[self.runLoopModes allObjects]];
    }
    [self.lock unlock];
}

- (void)cancelConnection {
    NSDictionary *userInfo = nil;
    if ([self.request URL]) {
        userInfo = [NSDictionary dictionaryWithObject:[self.request URL] forKey:NSURLErrorFailingURLErrorKey];
    }
    self.error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:userInfo];
    
    if (self.connection) {
        [self.connection cancel];
        
        // Manually send this delegate message since `[self.connection cancel]` causes the connection to never send another message to its delegate
        [self performSelector:@selector(connection:didFailWithError:) withObject:self.connection withObject:self.error];
    }
}

#pragma mark - NSURLConnectionDelegate

#ifdef _AFNETWORKING_PIN_SSL_CERTIFICATES_

- (void)connection:(NSURLConnection *)connection
willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if (self.authenticationChallenge) {
        self.authenticationChallenge(connection, challenge);
        return;
    }
    
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
        
        SecPolicyRef policy = SecPolicyCreateBasicX509();
        CFIndex certificateCount = SecTrustGetCertificateCount(serverTrust);
        NSMutableArray *trustChain = [NSMutableArray arrayWithCapacity:certificateCount];
        
        for (CFIndex i = 0; i < certificateCount; i++) {
            SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, i);
            
            if (self.SSLPinningMode == AFSSLPinningModeCertificate) {
                [trustChain addObject:(__bridge_transfer NSData *)SecCertificateCopyData(certificate)];
            } else if (self.SSLPinningMode == AFSSLPinningModePublicKey) {
                SecCertificateRef someCertificates[] = {certificate};
                CFArrayRef certificates = CFArrayCreate(NULL, (const void **)someCertificates, 1, NULL);
                
                SecTrustRef trust = NULL;
                
                OSStatus status = SecTrustCreateWithCertificates(certificates, policy, &trust);
                NSAssert(status == errSecSuccess, @"SecTrustCreateWithCertificates error: %ld", (long int)status);
                
                SecTrustResultType result;
                status = SecTrustEvaluate(trust, &result);
                NSAssert(status == errSecSuccess, @"SecTrustEvaluate error: %ld", (long int)status);
                
                [trustChain addObject:(__bridge_transfer id)SecTrustCopyPublicKey(trust)];
                
                CFRelease(trust);
                CFRelease(certificates);
            }
        }
        
        CFRelease(policy);
        
        switch (self.SSLPinningMode) {
            case AFSSLPinningModePublicKey: {
                NSArray *pinnedPublicKeys = [self.class pinnedPublicKeys];
                
                for (id publicKey in trustChain) {
                    for (id pinnedPublicKey in pinnedPublicKeys) {
                        if (AFSecKeyIsEqualToKey((__bridge SecKeyRef)publicKey, (__bridge SecKeyRef)pinnedPublicKey)) {
                            NSURLCredential *credential = [NSURLCredential credentialForTrust:serverTrust];
                            [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
                            return;
                        }
                    }
                }
                
                [[challenge sender] cancelAuthenticationChallenge:challenge];
                break;
            }
            case AFSSLPinningModeCertificate: {
                for (id serverCertificateData in trustChain) {
                    if ([[self.class pinnedCertificates] containsObject:serverCertificateData]) {
                        NSURLCredential *credential = [NSURLCredential credentialForTrust:serverTrust];
                        [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
                        return;
                    }
                }
                
                [[challenge sender] cancelAuthenticationChallenge:challenge];
                break;
            }
            case AFSSLPinningModeNone: {
                if (self.allowsInvalidSSLCertificate){
                    NSURLCredential *credential = [NSURLCredential credentialForTrust:serverTrust];
                    [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
                } else {
                    SecTrustResultType result = 0;
                    OSStatus status = SecTrustEvaluate(serverTrust, &result);
                    NSAssert(status == errSecSuccess, @"SecTrustEvaluate error: %ld", (long int)status);
                    
                    if (result == kSecTrustResultUnspecified || result == kSecTrustResultProceed) {
                        NSURLCredential *credential = [NSURLCredential credentialForTrust:serverTrust];
                        [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
                    } else {
                        [[challenge sender] cancelAuthenticationChallenge:challenge];
                    }
                }
                break;
            }
        }
    } else {
        if ([challenge previousFailureCount] == 0) {
            if (self.credential) {
                [[challenge sender] useCredential:self.credential forAuthenticationChallenge:challenge];
            } else {
                [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
            }
        } else {
            [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
        }
    }
}

#else

- (BOOL)connection:(NSURLConnection *)connection
canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    if (self.allowsInvalidSSLCertificate &&
       [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
            return YES;
    }
    
    if (self.authenticationAgainstProtectionSpace) {
        return self.authenticationAgainstProtectionSpace(connection, protectionSpace);
    } else if ([protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust] || [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodClientCertificate]) {
        return NO;
    } else {
        return YES;
    }
}

- (void)connection:(NSURLConnection *)connection
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{

    if (self.allowsInvalidSSLCertificate
       && [challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
        return;
    }

    if (self.authenticationChallenge) {
        self.authenticationChallenge(connection, challenge);
    } else {
        if ([challenge previousFailureCount] == 0) {
            if (self.credential) {
                [[challenge sender] useCredential:self.credential forAuthenticationChallenge:challenge];
            } else {
                [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
            }
        } else {
            [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
        }
    }
}

#endif

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection __unused *)connection {
    return self.shouldUseCredentialStorage;
}

- (NSInputStream *)connection:(NSURLConnection __unused *)connection
            needNewBodyStream:(NSURLRequest *)request
{
    if ([request.HTTPBodyStream conformsToProtocol:@protocol(NSCopying)]) {
        return [request.HTTPBodyStream copy];
    } else {
        [self cancelConnection];
        
        return nil;
    }
}

- (NSURLRequest *)connection:(NSURLConnection *)connection
             willSendRequest:(NSURLRequest *)request
            redirectResponse:(NSURLResponse *)redirectResponse
{
    if (self.redirectResponse) {
        return self.redirectResponse(connection, request, redirectResponse);
    } else {
        return request;
    }
}

- (void)connection:(NSURLConnection __unused *)connection
   didSendBodyData:(NSInteger)bytesWritten
 totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    if (self.uploadProgress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.uploadProgress((NSUInteger)bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
        });
    }
}

- (void)connection:(NSURLConnection __unused *)connection
didReceiveResponse:(NSURLResponse *)response
{
    self.response = response;
    
    [self.outputStream open];
}

- (void)connection:(NSURLConnection __unused *)connection
    didReceiveData:(NSData *)data
{
    NSUInteger length = [data length];
    if ([self.outputStream hasSpaceAvailable]) {
        const uint8_t *dataBuffer = (uint8_t *) [data bytes];
        [self.outputStream write:&dataBuffer[0] maxLength:length];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.totalBytesRead += length;
        
        if (self.downloadProgress) {
            self.downloadProgress(length, self.totalBytesRead, self.response.expectedContentLength);
        }
    });
}

- (void)connectionDidFinishLoading:(NSURLConnection __unused *)connection {
    self.responseData = [self.outputStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    
    [self.outputStream close];
    
    [self finish];
    
    self.connection = nil;
}

- (void)connection:(NSURLConnection __unused *)connection
  didFailWithError:(NSError *)error
{
    self.error = error;
    
    [self.outputStream close];
    
    [self finish];
    
    self.connection = nil;
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    if (self.cacheResponse) {
        return self.cacheResponse(connection, cachedResponse);
    } else {
        if ([self isCancelled]) {
            return nil;
        }
        
        return cachedResponse;
    }
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    NSURLRequest *request = [aDecoder decodeObjectForKey:@"request"];
    
    self = [self initWithRequest:request];
    if (!self) {
        return nil;
    }
    
    self.state = (AFOperationState)[aDecoder decodeIntegerForKey:@"state"];
    self.cancelled = [aDecoder decodeBoolForKey:@"isCancelled"];
    self.response = [aDecoder decodeObjectForKey:@"response"];
    self.error = [aDecoder decodeObjectForKey:@"error"];
    self.responseData = [aDecoder decodeObjectForKey:@"responseData"];
    self.totalBytesRead = [[aDecoder decodeObjectForKey:@"totalBytesRead"] longLongValue];
    self.allowsInvalidSSLCertificate = [[aDecoder decodeObjectForKey:@"allowsInvalidSSLCertificate"] boolValue];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [self pause];
    
    [aCoder encodeObject:self.request forKey:@"request"];
    
    switch (self.state) {
        case AFOperationExecutingState:
        case AFOperationPausedState:
            [aCoder encodeInteger:AFOperationReadyState forKey:@"state"];
            break;
        default:
            [aCoder encodeInteger:self.state forKey:@"state"];
            break;
    }
    
    [aCoder encodeBool:[self isCancelled] forKey:@"isCancelled"];
    [aCoder encodeObject:self.response forKey:@"response"];
    [aCoder encodeObject:self.error forKey:@"error"];
    [aCoder encodeObject:self.responseData forKey:@"responseData"];
    [aCoder encodeObject:[NSNumber numberWithLongLong:self.totalBytesRead] forKey:@"totalBytesRead"];
    [aCoder encodeObject:[NSNumber numberWithBool:self.allowsInvalidSSLCertificate] forKey:@"allowsInvalidSSLCertificate"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    AFURLConnectionOperation *operation = [(AFURLConnectionOperation *)[[self class] allocWithZone:zone] initWithRequest:self.request];
    
    operation.uploadProgress = self.uploadProgress;
    operation.downloadProgress = self.downloadProgress;
#ifndef _AFNETWORKING_PIN_SSL_CERTIFICATES_
    operation.authenticationAgainstProtectionSpace = self.authenticationAgainstProtectionSpace;
#endif
    operation.authenticationChallenge = self.authenticationChallenge;
    operation.cacheResponse = self.cacheResponse;
    operation.redirectResponse = self.redirectResponse;
    operation.allowsInvalidSSLCertificate = self.allowsInvalidSSLCertificate;
    
    return operation;
}

@end
