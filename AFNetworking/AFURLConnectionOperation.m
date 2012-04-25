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

typedef enum {
    AFHTTPOperationPausedState      = -1,
    AFHTTPOperationReadyState       = 1,
    AFHTTPOperationExecutingState   = 2,
    AFHTTPOperationFinishedState    = 3,
} _AFOperationState;

typedef signed short AFOperationState;

#if __IPHONE_OS_VERSION_MIN_REQUIRED
typedef UIBackgroundTaskIdentifier AFBackgroundTaskIdentifier;
#else
typedef id AFBackgroundTaskIdentifier;
#endif

static NSUInteger const kAFHTTPMinimumInitialDataCapacity = 1024;
static NSUInteger const kAFHTTPMaximumInitialDataCapacity = 1024 * 1024 * 8;

static NSString * const kAFNetworkingLockName = @"com.alamofire.networking.operation.lock";

NSString * const AFNetworkingErrorDomain = @"com.alamofire.networking.error";

NSString * const AFNetworkingOperationDidStartNotification = @"com.alamofire.networking.operation.start";
NSString * const AFNetworkingOperationDidFinishNotification = @"com.alamofire.networking.operation.finish";

typedef void (^AFURLConnectionOperationProgressBlock)(NSInteger bytes, long long totalBytes, long long totalBytesExpected);
typedef BOOL (^AFURLConnectionOperationAuthenticationAgainstProtectionSpaceBlock)(NSURLConnection *connection, NSURLProtectionSpace *protectionSpace);
typedef void (^AFURLConnectionOperationAuthenticationChallengeBlock)(NSURLConnection *connection, NSURLAuthenticationChallenge *challenge);
typedef NSCachedURLResponse * (^AFURLConnectionOperationCacheResponseBlock)(NSURLConnection *connection, NSCachedURLResponse *cachedResponse);

static inline NSString * AFKeyPathFromOperationState(AFOperationState state) {
    switch (state) {
        case AFHTTPOperationReadyState:
            return @"isReady";
        case AFHTTPOperationExecutingState:
            return @"isExecuting";
        case AFHTTPOperationFinishedState:
            return @"isFinished";
        case AFHTTPOperationPausedState:
            return @"isPaused";
        default:
            return @"state";
    }
}

static inline BOOL AFStateTransitionIsValid(AFOperationState fromState, AFOperationState toState, BOOL isCancelled) {
    switch (fromState) {
        case AFHTTPOperationReadyState:
            switch (toState) {
                case AFHTTPOperationPausedState:
                case AFHTTPOperationExecutingState:
                    return YES;
                case AFHTTPOperationFinishedState:
                    return isCancelled;
                default:
                    return NO;
            }
        case AFHTTPOperationExecutingState:
            switch (toState) {
                case AFHTTPOperationPausedState:
                case AFHTTPOperationFinishedState:
                    return YES;
                default:
                    return NO;
            }
        case AFHTTPOperationFinishedState:
            return NO;
        case AFHTTPOperationPausedState:
            return toState == AFHTTPOperationReadyState;
        default:
            return YES;
    }
}

@interface AFURLConnectionOperation ()
@property (readwrite, nonatomic, assign) AFOperationState state;
@property (readwrite, nonatomic, assign, getter = isCancelled) BOOL cancelled;
@property (readwrite, nonatomic, retain) NSRecursiveLock *lock;
@property (readwrite, nonatomic, retain) NSURLConnection *connection;
@property (readwrite, nonatomic, retain) NSURLRequest *request;
@property (readwrite, nonatomic, retain) NSURLResponse *response;
@property (readwrite, nonatomic, retain) NSError *error;
@property (readwrite, nonatomic, retain) NSData *responseData;
@property (readwrite, nonatomic, copy) NSString *responseString;
@property (readwrite, nonatomic, assign) long long totalBytesRead;
@property (readwrite, nonatomic, assign) AFBackgroundTaskIdentifier backgroundTaskIdentifier;
@property (readwrite, nonatomic, copy) AFURLConnectionOperationProgressBlock uploadProgress;
@property (readwrite, nonatomic, copy) AFURLConnectionOperationProgressBlock downloadProgress;
@property (readwrite, nonatomic, copy) AFURLConnectionOperationAuthenticationAgainstProtectionSpaceBlock authenticationAgainstProtectionSpace;
@property (readwrite, nonatomic, copy) AFURLConnectionOperationAuthenticationChallengeBlock authenticationChallenge;
@property (readwrite, nonatomic, copy) AFURLConnectionOperationCacheResponseBlock cacheResponse;

- (void)operationDidStart;
- (void)finish;
@end

@implementation AFURLConnectionOperation
@synthesize state = _state;
@synthesize cancelled = _cancelled;
@synthesize connection = _connection;
@synthesize runLoopModes = _runLoopModes;
@synthesize request = _request;
@synthesize response = _response;
@synthesize error = _error;
@synthesize responseData = _responseData;
@synthesize responseString = _responseString;
@synthesize totalBytesRead = _totalBytesRead;
@dynamic inputStream;
@synthesize outputStream = _outputStream;
@synthesize backgroundTaskIdentifier = _backgroundTaskIdentifier;
@synthesize uploadProgress = _uploadProgress;
@synthesize downloadProgress = _downloadProgress;
@synthesize authenticationAgainstProtectionSpace = _authenticationAgainstProtectionSpace;
@synthesize authenticationChallenge = _authenticationChallenge;
@synthesize cacheResponse = _cacheResponse;
@synthesize lock = _lock;

+ (void)networkRequestThreadEntryPoint:(id)__unused object {
    do {
        NSAutoreleasePool *runLoopPool = [[NSAutoreleasePool alloc] init];
        [[NSRunLoop currentRunLoop] run];
        [runLoopPool drain];
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

- (id)initWithRequest:(NSURLRequest *)urlRequest {
    self = [super init];
    if (!self) {
		return nil;
    }
    
    self.lock = [[[NSRecursiveLock alloc] init] autorelease];
    self.lock.name = kAFNetworkingLockName;
    
    self.runLoopModes = [NSSet setWithObject:NSRunLoopCommonModes];
    
    self.request = urlRequest;
    
    self.outputStream = [NSOutputStream outputStreamToMemory];
        
    self.state = AFHTTPOperationReadyState;
	
    return self;
}

- (void)dealloc {
    [_lock release];
        
    [_runLoopModes release];
    
    [_request release];
    [_response release];
    [_error release];
    
    [_responseData release];
    [_responseString release];
    
    if (_outputStream) {
        [_outputStream close];
        [_outputStream release];
        _outputStream = nil;
    }

#if __IPHONE_OS_VERSION_MIN_REQUIRED
    if (_backgroundTaskIdentifier) {
        [[UIApplication sharedApplication] endBackgroundTask:_backgroundTaskIdentifier];
        _backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    }
#endif
    	
    [_uploadProgress release];
    [_downloadProgress release];
    [_authenticationChallenge release];
    [_authenticationAgainstProtectionSpace release];
    [_cacheResponse release];
    
    [_connection release];
    
    [super dealloc];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, state: %@, cancelled: %@ request: %@, response: %@>", NSStringFromClass([self class]), self, AFKeyPathFromOperationState(self.state), ([self isCancelled] ? @"YES" : @"NO"), self.request, self.response];
}

- (void)setCompletionBlock:(void (^)(void))block {
    [self.lock lock];
    if (!block) {
        [super setCompletionBlock:nil];
    } else {
        __block id _blockSelf = self;
        [super setCompletionBlock:^ {
            block();
            [_blockSelf setCompletionBlock:nil];
        }];
    }
    [self.lock unlock];
}

- (NSInputStream *)inputStream {
    return self.request.HTTPBodyStream;
}

- (void)setInputStream:(NSInputStream *)inputStream {
    [self willChangeValueForKey:@"inputStream"];
    NSMutableURLRequest *mutableRequest = [[self.request mutableCopy] autorelease];
    mutableRequest.HTTPBodyStream = inputStream;
    self.request = mutableRequest;
    [self didChangeValueForKey:@"inputStream"];
}

- (void)setOutputStream:(NSOutputStream *)outputStream {
    [self willChangeValueForKey:@"outputStream"];
    [outputStream retain];
    [_outputStream release];
    _outputStream = outputStream;
    [self didChangeValueForKey:@"outputStream"];
    
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    for (NSString *runLoopMode in self.runLoopModes) {
        [self.outputStream scheduleInRunLoop:runLoop forMode:runLoopMode];
    }
}

#if __IPHONE_OS_VERSION_MIN_REQUIRED
- (void)setShouldExecuteAsBackgroundTaskWithExpirationHandler:(void (^)(void))handler {
    [self.lock lock];
    if (!self.backgroundTaskIdentifier) {    
        UIApplication *application = [UIApplication sharedApplication];
        self.backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^{
            if (handler) {
                handler();
            }
            
            [self cancel];
            
            [application endBackgroundTask:self.backgroundTaskIdentifier];
            self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }];
    }
    [self.lock unlock];
}
#endif

- (void)setUploadProgressBlock:(void (^)(NSInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))block {
    self.uploadProgress = block;
}

- (void)setDownloadProgressBlock:(void (^)(NSInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))block {
    self.downloadProgress = block;
}

- (void)setAuthenticationAgainstProtectionSpaceBlock:(BOOL (^)(NSURLConnection *, NSURLProtectionSpace *))block {
    self.authenticationAgainstProtectionSpace = block;
}

- (void)setAuthenticationChallengeBlock:(void (^)(NSURLConnection *connection, NSURLAuthenticationChallenge *challenge))block {
    self.authenticationChallenge = block;
}

- (void)setCacheResponseBlock:(NSCachedURLResponse * (^)(NSURLConnection *connection, NSCachedURLResponse *cachedResponse))block {
    self.cacheResponse = block;
}

- (void)setState:(AFOperationState)state {
    [self.lock lock];
    if (AFStateTransitionIsValid(self.state, state, [self isCancelled])) {
        NSString *oldStateKey = AFKeyPathFromOperationState(self.state);
        NSString *newStateKey = AFKeyPathFromOperationState(state);
        
        [self willChangeValueForKey:newStateKey];
        [self willChangeValueForKey:oldStateKey];
        _state = state;
        [self didChangeValueForKey:oldStateKey];
        [self didChangeValueForKey:newStateKey];
        
        switch (state) {
            case AFHTTPOperationExecutingState:
                [[NSNotificationCenter defaultCenter] postNotificationName:AFNetworkingOperationDidStartNotification object:self];
                break;
            case AFHTTPOperationFinishedState:
                [[NSNotificationCenter defaultCenter] postNotificationName:AFNetworkingOperationDidFinishNotification object:self];
                break;
            default:
                break;
        }
    }
    [self.lock unlock];
}

- (NSString *)responseString {
    [self.lock lock];
    if (!_responseString && self.response && self.responseData) {
        NSStringEncoding textEncoding = NSUTF8StringEncoding;
        if (self.response.textEncodingName) {
            textEncoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)self.response.textEncodingName));
        }
        
        self.responseString = [[[NSString alloc] initWithData:self.responseData encoding:textEncoding] autorelease];
    }
    [self.lock unlock];
    
    return _responseString;
}

- (void)pause {
    if ([self isPaused]) {
        return;
    }
    
    [self.lock lock];
    self.state = AFHTTPOperationPausedState;
    
    [self.connection performSelector:@selector(cancel) onThread:[[self class] networkRequestThread] withObject:nil waitUntilDone:NO modes:[self.runLoopModes allObjects]];
    [[NSNotificationCenter defaultCenter] postNotificationName:AFNetworkingOperationDidFinishNotification object:self];
    [self.lock unlock];
}

- (BOOL)isPaused {
    return self.state == AFHTTPOperationPausedState;
}

- (void)resume {
    if (![self isPaused]) {
        return;
    }
    
    [self.lock lock];
    self.state = AFHTTPOperationReadyState;
    
    [self start];
    [self.lock unlock];
}

#pragma mark - NSOperation

- (BOOL)isReady {
    return self.state == AFHTTPOperationReadyState && [super isReady];
}

- (BOOL)isExecuting {
    return self.state == AFHTTPOperationExecutingState;
}

- (BOOL)isFinished {
    return self.state == AFHTTPOperationFinishedState;
}

- (BOOL)isConcurrent {
    return YES;
}

- (void)start {
    [self.lock lock];
    if ([self isReady]) {
        self.state = AFHTTPOperationExecutingState;
        
        [self performSelector:@selector(operationDidStart) onThread:[[self class] networkRequestThread] withObject:nil waitUntilDone:NO modes:[self.runLoopModes allObjects]];
    }
    [self.lock unlock];
}

- (void)operationDidStart {
    [self.lock lock];
    if ([self isCancelled]) {
        [self finish];
    } else {
        self.connection = [[[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO] autorelease];
        
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        for (NSString *runLoopMode in self.runLoopModes) {
            [self.connection scheduleInRunLoop:runLoop forMode:runLoopMode];
            [self.outputStream scheduleInRunLoop:runLoop forMode:runLoopMode];
        }
        
        [self.connection start];  
    }
    [self.lock unlock];
}

- (void)finish {
    self.state = AFHTTPOperationFinishedState;
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
    if (self.connection) {
        [self.connection cancel];
        
        // Manually send this delegate message since `[self.connection cancel]` causes the connection to never send another message to its delegate
        NSDictionary *userInfo = nil;
        if ([self.request URL]) {
            userInfo = [NSDictionary dictionaryWithObject:[self.request URL] forKey:NSURLErrorFailingURLErrorKey];
        }
        [self performSelector:@selector(connection:didFailWithError:) withObject:self.connection withObject:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:userInfo]];
    }
}

#pragma mark - NSURLConnectionDelegate

- (BOOL)connection:(NSURLConnection *)connection 
canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
#ifdef _AFNETWORKING_ALLOW_INVALID_SSL_CERTIFICATES_
    if ([protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        return YES;
    }
#endif
    
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
#ifdef _AFNETWORKING_ALLOW_INVALID_SSL_CERTIFICATES_
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
        return;
    }
#endif
    
    if (self.authenticationChallenge) {
        self.authenticationChallenge(connection, challenge);
    } else {
        if ([challenge previousFailureCount] == 0) {
            NSURLCredential *credential = nil;
            
            NSString *username = [(NSString *)CFURLCopyUserName((CFURLRef)[self.request URL]) autorelease];
            NSString *password = [(NSString *)CFURLCopyPassword((CFURLRef)[self.request URL]) autorelease];
            
            if (username && password) {
                credential = [NSURLCredential credentialWithUser:username password:password persistence:NSURLCredentialPersistenceNone];
            } else if (username) {
                credential = [[[NSURLCredentialStorage sharedCredentialStorage] credentialsForProtectionSpace:[challenge protectionSpace]] objectForKey:username];
            } else {
                credential = [[NSURLCredentialStorage sharedCredentialStorage] defaultCredentialForProtectionSpace:[challenge protectionSpace]];
            }
            
            if (credential) {
                [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
            } else {
                [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
            }
        } else {
            [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
        }
    }
}

- (void)connection:(NSURLConnection *)__unused connection 
   didSendBodyData:(NSInteger)bytesWritten 
 totalBytesWritten:(NSInteger)totalBytesWritten 
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    if (self.uploadProgress) {
        self.uploadProgress(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
    }
}

- (void)connection:(NSURLConnection *)__unused connection 
didReceiveResponse:(NSURLResponse *)response 
{
    self.response = response;
    
    [self.outputStream open];
}

- (void)connection:(NSURLConnection *)__unused connection 
    didReceiveData:(NSData *)data
{
    self.totalBytesRead += [data length];
    
    if ([self.outputStream hasSpaceAvailable]) {
        const uint8_t *dataBuffer = (uint8_t *) [data bytes];
        [self.outputStream write:&dataBuffer[0] maxLength:[data length]];
    }
    
    if (self.downloadProgress) {
        self.downloadProgress((long long)[data length], self.totalBytesRead, self.response.expectedContentLength);
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)__unused connection {
    self.responseData = [self.outputStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    
    [self.outputStream close];
    
    [self finish];

    self.connection = nil;
}

- (void)connection:(NSURLConnection *)__unused connection 
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

@end
