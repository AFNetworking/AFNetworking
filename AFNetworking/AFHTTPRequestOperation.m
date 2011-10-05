// AFHTTPOperation.m
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

#import "AFHTTPRequestOperation.h"

static NSUInteger const kAFHTTPMinimumInitialDataCapacity = 1024;
static NSUInteger const kAFHTTPMaximumInitialDataCapacity = 1024 * 1024 * 8;

typedef enum {
    AFHTTPOperationReadyState       = 1,
    AFHTTPOperationExecutingState   = 2,
    AFHTTPOperationFinishedState    = 3,
    AFHTTPOperationCancelledState   = 4,
} AFHTTPOperationState;

NSString * const AFNetworkingErrorDomain = @"com.alamofire.networking.error";

NSString * const AFHTTPOperationDidStartNotification = @"com.alamofire.networking.http-operation.start";
NSString * const AFHTTPOperationDidFinishNotification = @"com.alamofire.networking.http-operation.finish";

typedef void (^AFHTTPRequestOperationProgressBlock)(NSInteger bytes, NSInteger totalBytes, NSInteger totalBytesExpected);
typedef void (^AFHTTPRequestOperationCompletionBlock)(NSURLRequest *request, NSHTTPURLResponse *response, NSData *data, NSError *error);

static inline NSString * AFKeyPathFromOperationState(AFHTTPOperationState state) {
    switch (state) {
        case AFHTTPOperationReadyState:
            return @"isReady";
        case AFHTTPOperationExecutingState:
            return @"isExecuting";
        case AFHTTPOperationFinishedState:
            return @"isFinished";
        default:
            return @"state";
    }
}

static inline BOOL AFHTTPOperationStateTransitionIsValid(AFHTTPOperationState from, AFHTTPOperationState to) {
    switch (from) {
        case AFHTTPOperationReadyState:
            switch (to) {
                case AFHTTPOperationExecutingState:
                    return YES;
                default:
                    return NO;
            }
        case AFHTTPOperationExecutingState:
            switch (to) {
                case AFHTTPOperationReadyState:
                    return NO;
                default:
                    return YES;
            }
        case AFHTTPOperationFinishedState:
            return NO;
        default:
            return YES;
    }
}

@interface AFHTTPRequestOperation ()
@property (readwrite, nonatomic, assign) AFHTTPOperationState state;
@property (readwrite, nonatomic, assign, getter = isCancelled) BOOL cancelled;
@property (readwrite, nonatomic, retain) NSURLConnection *connection;
@property (readwrite, nonatomic, retain) NSURLRequest *request;
@property (readwrite, nonatomic, retain) NSHTTPURLResponse *response;
@property (readwrite, nonatomic, retain) NSError *error;
@property (readwrite, nonatomic, retain) NSData *responseBody;
@property (readwrite, nonatomic, assign) NSInteger totalBytesRead;
@property (readwrite, nonatomic, retain) NSMutableData *dataAccumulator;
@property (readwrite, nonatomic, retain) NSOutputStream *outputStream;
@property (readwrite, nonatomic, copy) AFHTTPRequestOperationProgressBlock uploadProgress;
@property (readwrite, nonatomic, copy) AFHTTPRequestOperationProgressBlock downloadProgress;
@property (readwrite, nonatomic, copy) AFHTTPRequestOperationCompletionBlock completion;

- (void)operationDidStart;
- (void)finish;
@end

@implementation AFHTTPRequestOperation
@synthesize state = _state;
@synthesize cancelled = _cancelled;
@synthesize connection = _connection;
@synthesize runLoopModes = _runLoopModes;
@synthesize request = _request;
@synthesize response = _response;
@synthesize error = _error;
@synthesize responseBody = _responseBody;
@synthesize totalBytesRead = _totalBytesRead;
@synthesize dataAccumulator = _dataAccumulator;
@synthesize outputStream = _outputStream;
@synthesize uploadProgress = _uploadProgress;
@synthesize downloadProgress = _downloadProgress;
@synthesize completion = _completion;

static NSThread *_networkRequestThread = nil;

+ (void)networkRequestThreadEntryPoint:(id)__unused object {
    do {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        [[NSRunLoop currentRunLoop] run];
        [pool drain];
    } while (YES);
}

+ (NSThread *)networkRequestThread {
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        _networkRequestThread = [[NSThread alloc] initWithTarget:self selector:@selector(networkRequestThreadEntryPoint:) object:nil];
        [_networkRequestThread start];
    });
        
    return _networkRequestThread;
}

+ (AFHTTPRequestOperation *)operationWithRequest:(NSURLRequest *)urlRequest 
                completion:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSData *data, NSError *error))completion
{
    AFHTTPRequestOperation *operation = [[[self alloc] init] autorelease];
    operation.request = urlRequest;
    operation.completion = completion;
    
    return operation;
}

+ (AFHTTPRequestOperation *)streamingOperationWithRequest:(NSURLRequest *)urlRequest
                                              inputStream:(NSInputStream *)inputStream
                                             outputStream:(NSOutputStream *)outputStream
                                               completion:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))completion
{
    NSMutableURLRequest *mutableURLRequest = [[urlRequest mutableCopy] autorelease];
    if (inputStream) {
        [mutableURLRequest setHTTPBodyStream:inputStream];
        if ([[mutableURLRequest HTTPMethod] isEqualToString:@"GET"]) {
            [mutableURLRequest setHTTPMethod:@"POST"];
        }
    }

    AFHTTPRequestOperation *operation = [self operationWithRequest:mutableURLRequest completion:^(NSURLRequest *request, NSHTTPURLResponse *response, __unused NSData *data, NSError *error) {
        if (completion) {
            completion(request, response, error);
        }
    }];
    
    operation.outputStream = outputStream;
    
    return operation;
}

- (id)init {
    self = [super init];
    if (!self) {
		return nil;
    }
    	
    self.runLoopModes = [NSSet setWithObject:NSRunLoopCommonModes];
    
    self.state = AFHTTPOperationReadyState;
	
    return self;
}

- (void)dealloc {
    [_runLoopModes release];
    
    [_request release];
    [_response release];
    [_responseBody release];
    [_dataAccumulator release];
    [_outputStream release]; _outputStream = nil;
    
    [_connection release]; _connection = nil;
	
    [_uploadProgress release];
    [_downloadProgress release];
    [_completion release];
    [super dealloc];
}

- (void)setUploadProgressBlock:(void (^)(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))block {
    self.uploadProgress = block;
}

- (void)setDownloadProgressBlock:(void (^)(NSInteger bytesRead, NSInteger totalBytesRead, NSInteger totalBytesExpectedToRead))block {
    self.downloadProgress = block;
}

- (void)setState:(AFHTTPOperationState)state {
    if (self.state == state) {
        return;
    }
    
    if (!AFHTTPOperationStateTransitionIsValid(self.state, state)) {
        return;
    }
    
    NSString *oldStateKey = AFKeyPathFromOperationState(self.state);
    NSString *newStateKey = AFKeyPathFromOperationState(state);
    
    [self willChangeValueForKey:newStateKey];
    [self willChangeValueForKey:oldStateKey];
    _state = state;
    [self didChangeValueForKey:oldStateKey];
    [self didChangeValueForKey:newStateKey];
    
#if __IPHONE_OS_VERSION_MIN_REQUIRED
    switch (state) {
        case AFHTTPOperationExecutingState:
            [[NSNotificationCenter defaultCenter] postNotificationName:AFHTTPOperationDidStartNotification object:self];
            break;
        case AFHTTPOperationFinishedState:
            [[NSNotificationCenter defaultCenter] postNotificationName:AFHTTPOperationDidFinishNotification object:self];
            break;
        default:
            break;
    }
#endif
}

- (void)setCancelled:(BOOL)cancelled {
    [self willChangeValueForKey:@"isCancelled"];
    _cancelled = cancelled;
    [self didChangeValueForKey:@"isCancelled"];
    
    if ([self isCancelled]) {
        self.state = AFHTTPOperationFinishedState;
    }
}

- (NSString *)responseString {
    if (!self.response || !self.responseBody) {
        return nil;
    }
    
    NSStringEncoding textEncoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)self.response.textEncodingName));
    
    return [[[NSString alloc] initWithData:self.responseBody encoding:textEncoding] autorelease];
}

#pragma mark - NSOperation

- (BOOL)isReady {
    return self.state == AFHTTPOperationReadyState;
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
    if (![self isReady]) {
        return;
    }
        
    self.state = AFHTTPOperationExecutingState;

    [self performSelector:@selector(operationDidStart) onThread:[[self class] networkRequestThread] withObject:nil waitUntilDone:YES modes:[self.runLoopModes allObjects]];
}

- (void)operationDidStart {
    self.connection = [[[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO] autorelease];
    
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    for (NSString *runLoopMode in self.runLoopModes) {
        [self.connection scheduleInRunLoop:runLoop forMode:runLoopMode];
        [self.outputStream scheduleInRunLoop:runLoop forMode:runLoopMode];
    }
    
    [self.connection start];
}

- (void)cancel {
    if ([self isFinished]) {
        return;
    }
    
    [super cancel];
    
    self.cancelled = YES;
    
    [self.connection cancel];
}

- (void)finish {
    self.state = AFHTTPOperationFinishedState;
    
    if ([self isCancelled]) {
        return;
    }
    
    if (self.completion) {
        self.completion(self.request, self.response, self.responseBody, self.error);
    }
}

#pragma mark - NSURLConnection

- (void)connection:(NSURLConnection *)__unused connection 
didReceiveResponse:(NSURLResponse *)response 
{
    self.response = (NSHTTPURLResponse *)response;
    
    if (self.outputStream) {
        [self.outputStream open];
    } else {
        
        NSUInteger maxCapacity = MAX((NSUInteger)llabs(response.expectedContentLength), kAFHTTPMinimumInitialDataCapacity);
        NSUInteger capacity = MIN(maxCapacity, kAFHTTPMaximumInitialDataCapacity);
        self.dataAccumulator = [NSMutableData dataWithCapacity:capacity];
    }
}

- (void)connection:(NSURLConnection *)__unused connection 
    didReceiveData:(NSData *)data 
{
    self.totalBytesRead += [data length];
    
    if (self.outputStream) {
        if ([self.outputStream hasSpaceAvailable]) {
            const uint8_t *dataBuffer = [data bytes];
            [self.outputStream write:&dataBuffer[0] maxLength:[data length]];
        }
    } else {
        [self.dataAccumulator appendData:data];
    }
    
    if (self.downloadProgress) {
        self.downloadProgress([data length], self.totalBytesRead, (NSInteger)self.response.expectedContentLength);
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)__unused connection {        
    if (self.outputStream) {
        [self.outputStream close];
    } else {
        self.responseBody = [NSData dataWithData:self.dataAccumulator];
        [_dataAccumulator release]; _dataAccumulator = nil;
    }

    [self finish];
}

- (void)connection:(NSURLConnection *)__unused connection 
  didFailWithError:(NSError *)error 
{      
    self.error = error;
    
    if (self.outputStream) {
        [self.outputStream close];
    } else {
        [_dataAccumulator release]; _dataAccumulator = nil;
    }
    
    [self finish];
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

- (NSCachedURLResponse *)connection:(NSURLConnection *)__unused connection 
                  willCacheResponse:(NSCachedURLResponse *)cachedResponse 
{
    if ([self isCancelled]) {
        return nil;
    }
    
    return cachedResponse;
}

@end
