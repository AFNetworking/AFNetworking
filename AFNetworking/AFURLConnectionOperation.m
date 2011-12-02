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

static dispatch_queue_t af_request_operation_execution_block_queue;
static dispatch_queue_t request_operation_execution_block_queue() {
    if (af_request_operation_execution_block_queue == NULL) {
        af_request_operation_execution_block_queue = dispatch_queue_create("com.alamofire.networking.request.execution", DISPATCH_QUEUE_CONCURRENT);
    }
    
    return af_request_operation_execution_block_queue;
}

static NSUInteger const kAFHTTPMinimumInitialDataCapacity = 1024;
static NSUInteger const kAFHTTPMaximumInitialDataCapacity = 1024 * 1024 * 8;

typedef enum {
    AFHTTPOperationReadyState       = 1,
    AFHTTPOperationExecutingState   = 2,
    AFHTTPOperationFinishedState    = 3,
} AFOperationState;

NSString * const AFNetworkingErrorDomain = @"com.alamofire.networking.error";

NSString * const AFNetworkingOperationDidStartNotification = @"com.alamofire.networking.operation.start";
NSString * const AFNetworkingOperationDidFinishNotification = @"com.alamofire.networking.operation.finish";

typedef void (^AFURLConnectionOperationProgressBlock)(NSInteger bytes, NSInteger totalBytes, NSInteger totalBytesExpected);

static inline NSString * AFKeyPathFromOperationState(AFOperationState state) {
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

@interface AFURLConnectionOperation ()
@property (readwrite, nonatomic, assign) AFOperationState state;
@property (readwrite, nonatomic, assign) NSURLConnection *connection;
@property (readwrite, nonatomic, retain) NSURLRequest *request;
@property (readwrite, nonatomic, retain) NSURLResponse *response;
@property (readwrite, nonatomic, retain) NSData *responseData;
@property (readwrite, nonatomic, copy) NSString *responseString;
@property (readwrite, nonatomic, assign) NSInteger totalBytesRead;
@property (readwrite, nonatomic, retain) NSMutableData *dataAccumulator;
@property (readwrite, nonatomic, copy) AFURLConnectionOperationProgressBlock uploadProgress;
@property (readwrite, nonatomic, copy) AFURLConnectionOperationProgressBlock downloadProgress;

- (BOOL)shouldTransitionToState:(AFOperationState)state;
- (void)operationDidStart;
- (void)finish;
@end

@implementation AFURLConnectionOperation
@synthesize state = _state;

@synthesize connection = _connection;
@synthesize runLoopModes = _runLoopModes;
@synthesize request = _request;
@synthesize response = _response;
@synthesize error = _error;
@synthesize responseData = _responseData;
@synthesize responseString = _responseString;
@synthesize totalBytesRead = _totalBytesRead;
@synthesize dataAccumulator = _dataAccumulator;
@dynamic inputStream;
@synthesize outputStream = _outputStream;
@synthesize uploadProgress = _uploadProgress;
@synthesize downloadProgress = _downloadProgress;
@synthesize cacheStoragePolicy = _cacheStoragePolicy;
@dynamic executionBlocks;

+ (void)networkRequestThreadEntryPoint:(id)__unused object {
    do {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        [[NSRunLoop currentRunLoop] run];
        [pool drain];
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
    
    self.cacheStoragePolicy = AFURLCacheStorageDefault;
    self.runLoopModes = [NSSet setWithObject:NSRunLoopCommonModes];
    
    self.request = urlRequest;
    
    self.state = AFHTTPOperationReadyState;
    _executionBlocks = [NSMutableArray arrayWithCapacity:1];
    
    return self;
}

- (void)dealloc {
    [_executionBlocks release];
    [_runLoopModes release];
    
    [_request release];
    [_response release];
    [_error release];
    
    [_responseData release];
    [_responseString release];
    [_dataAccumulator release];
    [_outputStream release]; _outputStream = nil;
    
    [_connection release]; _connection = nil;
	
    [_uploadProgress release];
    [_downloadProgress release];

    [super dealloc];
}

- (NSInputStream *)inputStream {
    return self.request.HTTPBodyStream;
}

- (void)setInputStream:(NSInputStream *)inputStream {
    NSMutableURLRequest *mutableRequest = [[self.request mutableCopy] autorelease];
    mutableRequest.HTTPBodyStream = inputStream;
    self.request = mutableRequest;
}

- (void)setUploadProgressBlock:(void (^)(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))block {
    self.uploadProgress = block;
}

- (void)setDownloadProgressBlock:(void (^)(NSInteger bytesRead, NSInteger totalBytesRead, NSInteger totalBytesExpectedToRead))block {
    self.downloadProgress = block;
}

- (AFOperationState) state {
    @synchronized(self)
    {
        return _state;
    }
}

- (void)setState:(AFOperationState)state {
    @synchronized(self)
    {
        if (![self shouldTransitionToState:state]) {
            return;
        }
        
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
}

- (BOOL)shouldTransitionToState:(AFOperationState)state {    
    switch (self.state) {
        case AFHTTPOperationReadyState:
            switch (state) {
                case AFHTTPOperationExecutingState:
                    return YES;
                default:
                    return NO;
            }
        case AFHTTPOperationExecutingState:
            switch (state) {
                case AFHTTPOperationFinishedState:
                    return YES;
                default:
                    return NO;
            }
        case AFHTTPOperationFinishedState:
            return NO;
        default:
            return YES;
    }
}

- (NSString *)responseString {
    if (!_responseString && self.response && self.responseData) {
        NSStringEncoding textEncoding = NSUTF8StringEncoding;
        if (self.response.textEncodingName) {
            textEncoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)self.response.textEncodingName));
        }
        
        self.responseString = [[[NSString alloc] initWithData:self.responseData encoding:textEncoding] autorelease];
    }
    
    return _responseString;
}

- (void)setCompletionBlock:(void (^)(void))block {
    if (!block) {
        [super setCompletionBlock:nil];
    } else {
        __block id _blockSelf = self;
        [super setCompletionBlock:^ {
            block();
            [_blockSelf setCompletionBlock:nil];
        }];
    }
}


#pragma mark - NSOperation

- (BOOL)isReady {
    return (self.state == AFHTTPOperationReadyState && [super isReady]);
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
    if ([self isCancelled])
    {
        [self finish];
        return;
    }
    
    if (![self isReady]) {
        return;
    }
    
    self.state = AFHTTPOperationExecutingState;
    
    [self performSelector:@selector(operationDidStart) onThread:[[self class] networkRequestThread] withObject:nil waitUntilDone:YES modes:[self.runLoopModes allObjects]];
}

- (void)operationDidStart {
    if ([self isCancelled]) {
        [self finish];
        return;
    }
    
    self.connection = [[[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO] autorelease];
    
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    for (NSString *runLoopMode in self.runLoopModes) {
        [self.connection scheduleInRunLoop:runLoop forMode:runLoopMode];
        [self.outputStream scheduleInRunLoop:runLoop forMode:runLoopMode];
    }
    
    [self.connection start];
}

- (void)finish {
    self.state = AFHTTPOperationFinishedState;
}

- (void)cancel {
    if ([self isExecuting] ) {
        [self.connection cancel];
    }

    [super cancel];
}

#pragma mark - NSURLConnectionDelegate

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
        self.responseData = [NSData dataWithData:self.dataAccumulator];
        [_dataAccumulator release]; _dataAccumulator = nil;
    }
    
    if ([_executionBlocks count] > 0) {
        dispatch_async(request_operation_execution_block_queue(), ^{
            NSArray *_executionBlocksCopy;
            @synchronized(_executionBlocks) {
                //handle a potential race
                _executionBlocksCopy = [_executionBlocks copy];
                [_executionBlocks removeAllObjects];
            }
            for (void(^executionBlock)(void) in _executionBlocksCopy)
            {
                if ([self isCancelled]) 
                    break;
                executionBlock();
            }
            [_executionBlocksCopy release];
            [self finish];
        });
    }
    else {
        [self finish];
    }
    
   
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
    
    @synchronized(_executionBlocks){
        [_executionBlocks removeAllObjects];
    }
    
    [self finish];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)__unused connection 
                  willCacheResponse:(NSCachedURLResponse *)cachedResponse 
{
    if ([self isCancelled]) {
        return nil;
    }
    
    if (self.cacheStoragePolicy == AFURLCacheStorageDefault 
        || self.cacheStoragePolicy == cachedResponse.storagePolicy) {
        return cachedResponse;
    }
    else {
        NSCachedURLResponse *alternativeCachedResponse = 
        [[NSCachedURLResponse alloc] initWithResponse:cachedResponse.response
                                                 data:cachedResponse.data
                                             userInfo:cachedResponse.userInfo
                                        storagePolicy:self.cacheStoragePolicy];
        return [alternativeCachedResponse autorelease];
    }
}

- (void)addExecutionBlock:(void(^)(void))executionBlock {
    if ([self isExecuting] || [self isFinished] || executionBlock==nil){
        //Following the NSBlockOperation concept.
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"operation has already began executing" userInfo:nil];
    }
    @synchronized(_executionBlocks) {
        [_executionBlocks addObject:[[executionBlock copy] autorelease]];
    }
}

- (NSArray *)executionBlocks {
    @synchronized(_executionBlocks)
    {
        return [[_executionBlocks copy] autorelease];
    }
}

@end
