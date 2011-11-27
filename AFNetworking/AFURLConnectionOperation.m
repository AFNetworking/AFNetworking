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
#include <libkern/OSAtomic.h>

static NSUInteger const kAFHTTPMinimumInitialDataCapacity = 1024;
static NSUInteger const kAFHTTPMaximumInitialDataCapacity = 1024 * 1024 * 8;

enum {
    AFOperationMinState           = 0, // Must be equal to the lowest used state.  Used internally to do assertions.
    AFOperationUninitializedState = 0,
    AFOperationReadyState         = 1,
    AFOperationExecutingState     = 2,
    AFOperationFinishedState      = 3,
    AFOperationMaxState           = 3, // Must be equal to the highest used state.  Used internally to do assertions.
    AFOperationCancelledFlag      = (1 << 8),
    AFOperationStateMask          = (0xff),
    AFOperationStateValidFlags    = (AFOperationCancelledFlag), // Must contain all the valid flags.  Used internally to do assertions.
};

static BOOL af_tryToTransitionToState(AFURLConnectionOperation *operation, NSUInteger toState, BOOL setCancelled, NSUInteger *oldStatePtr, NSUInteger *newStatePtr);

NSString * const AFNetworkingErrorDomain = @"com.alamofire.networking.error";

NSString * const AFNetworkingOperationDidStartNotification = @"com.alamofire.networking.operation.start";
NSString * const AFNetworkingOperationDidFinishNotification = @"com.alamofire.networking.operation.finish";

typedef void (^AFURLConnectionOperationProgressBlock)(NSInteger bytes, NSInteger totalBytes, NSInteger totalBytesExpected);

@interface AFURLConnectionOperation ()
@property (readwrite, nonatomic, retain) NSURLConnection *connection;
@property (readwrite, nonatomic, copy) NSURLRequest *request;
@property (readwrite, nonatomic, retain) NSURLResponse *response;
@property (readwrite, nonatomic, retain) NSError *error;
@property (readwrite, nonatomic, retain) NSData *responseData;
@property (readwrite, nonatomic, copy) NSString *responseString;
@property (readwrite, nonatomic, assign) NSInteger totalBytesRead;
@property (readwrite, nonatomic, retain) NSMutableData *dataAccumulator;
@property (readwrite, nonatomic, copy) AFURLConnectionOperationProgressBlock uploadProgress;
@property (readwrite, nonatomic, copy) AFURLConnectionOperationProgressBlock downloadProgress;

- (void)operationDidStart;
- (void)finish;
+ (NSThread *)networkRequestThread;
+ (void)startNetworkRequestPeriodicTimerIfNeeded;
+ (void)networkRequestPeriodicTimer:(NSTimer*)theTimer;

@end

@implementation AFURLConnectionOperation
@synthesize connection = _connection;
@synthesize request = _request;
@synthesize response = _response;
@synthesize error = _error;
@synthesize responseData = _responseData;
@synthesize responseString = _responseString;
@synthesize totalBytesRead = _totalBytesRead;
@synthesize dataAccumulator = _dataAccumulator;
@dynamic httpBody;
@dynamic inputStream;
@synthesize outputStream = _outputStream;
@synthesize uploadProgress = _uploadProgress;
@synthesize downloadProgress = _downloadProgress;


static dispatch_once_t  _networkRequestThreadOncePredicate;
static NSThread        *_networkRequestThread;
static OSSpinLock       _networkRequestThreadSpinLock;
static BOOL             _networkRequestThreadPeriodicTimerScheduled;
static NSMutableSet    *_networkRequestThreadExecutingRequestsSet;

+ (void)startNetworkRequestPeriodicTimerIfNeeded
{
    if([NSThread currentThread] != [[self class] networkRequestThread]) { [self performSelector:@selector(startNetworkRequestPeriodicTimer) onThread:[[self class] networkRequestThread] withObject:NULL waitUntilDone:NO]; return; }
    else {
        OSSpinLockLock(&_networkRequestThreadSpinLock);
        if((_networkRequestThreadPeriodicTimerScheduled == NO) && ([_networkRequestThreadExecutingRequestsSet count] > 0)) {
            [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(networkRequestPeriodicTimer:) userInfo:NULL repeats:NO];
            _networkRequestThreadPeriodicTimerScheduled = YES;
        }
        OSSpinLockUnlock(&_networkRequestThreadSpinLock);
    }
}

+ (void)networkRequestPeriodicTimer:(NSTimer *)theTimer
{
    OSSpinLockLock(&_networkRequestThreadSpinLock);
    _networkRequestThreadPeriodicTimerScheduled = NO;

    NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
    for(NSValue *operationValue in _networkRequestThreadExecutingRequestsSet) {
        AFURLConnectionOperation *operation = [operationValue pointerValue];
        if((currentTime - operation->_lastUpdateTime) > operation->_cancelAfterInactivityTime) { [operation cancel]; }
    }

    OSSpinLockUnlock(&_networkRequestThreadSpinLock);

    [self startNetworkRequestPeriodicTimerIfNeeded];
}

+ (void)networkRequestDistantFutureTimer:(NSTimer *)theTimer
{
    // Intentially does nothing.
}

+ (void)networkRequestThreadEntryPoint:(id)__unused object {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSRunLoop *currentRunLoop = [NSRunLoop currentRunLoop];

    NSTimer *distantFutureTimer = [[[NSTimer alloc] initWithFireDate:[NSDate distantFuture] interval:0.0 target:self selector:@selector(networkRequestDistantFutureTimer:) userInfo:NULL repeats:NO] autorelease];
    [currentRunLoop addTimer:distantFutureTimer forMode:NSRunLoopCommonModes]; // This "does nothing", but stops the run loop from exiting immediately due to "no work / sources".
    
    do {
        NSAutoreleasePool *exceptionPool = [[NSAutoreleasePool alloc] init];
        NSException *caughtException = NULL;
        @try {
            NSAutoreleasePool *loopPool = [[NSAutoreleasePool alloc] init];
            [currentRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
            [loopPool drain];
        }
        @catch(NSException *e) { caughtException = e; }
        if(caughtException != NULL) { NSLog(@"Unhandled exception on %@ networking thread: %@, userInfo: %@", NSStringFromClass([self class]), caughtException, [caughtException userInfo]); }
        [exceptionPool drain];
    } while (YES);

    [pool drain];
}

+ (NSThread *)networkRequestThread {
    dispatch_once(&_networkRequestThreadOncePredicate, ^{
        _networkRequestThreadExecutingRequestsSet = [[NSMutableSet alloc] init];
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
    
    if((_lock = [[NSRecursiveLock alloc] init]) == NULL) { [self autorelease]; return(NULL); }
    [_lock setName:[NSString stringWithFormat:@"Owned by <%@: %p>", NSStringFromClass([self class]), self]];
    
    _request = [urlRequest copy];
    
    _cancelAfterInactivityTime = MAX(_request.timeoutInterval, 5.0);

    NSUInteger oldState = 0, newState = 0;
    if(af_tryToTransitionToState(self, AFOperationReadyState, NO, &oldState, &newState) == NO) { [NSException raise:NSInternalInconsistencyException format:@"Unable to transition from unitialized to ready state.  oldState: %u, newState: %u", oldState, newState]; }
    _stateVisibleToKVO = newState;
    
    return self;
}

- (void)dealloc {
#ifndef NS_BLOCK_ASSERTIONS
    OSSpinLockLock(&_networkRequestThreadSpinLock);
    BOOL containsOp = [_networkRequestThreadExecutingRequestsSet containsObject:[NSValue valueWithNonretainedObject:self]];
    if(containsOp == YES) { [_networkRequestThreadExecutingRequestsSet removeObject:[NSValue valueWithNonretainedObject:self]]; }
    OSSpinLockUnlock(&_networkRequestThreadSpinLock);
    if(containsOp == YES) { NSLog(@"WARNING: The network threads executing requests set contained this operation in %@!", NSStringFromSelector(_cmd)); }
#endif

    [_lock release];

    [_connection cancel]; // NSURLConnection -cancel method is documented as "Once this method is called, the receiver's delegate will no longer receive any messages for this NSURLConnection."
                          // This ensures that in the unlikely situation where _connection was not cleanly shut down, we won't leave it with a dangling delegate pointer... which may cause a crash later on.
    [_connection release];
    
    [_request release];
    [_response release];
    [_error release];
    
    [_responseData release];
    [_responseString release]; _responseStringVisibleToKVO = NULL; // XXX _responseString is the "true" value for our retain count accounting purposes.
    [_dataAccumulator release];
    if(_outputStream != NULL) { [_outputStream close]; [_outputStream release]; _outputStream = nil; }
    	
    [_uploadProgress release];
    [_downloadProgress release];

    [super dealloc];
}

- (void)setCompletionBlock:(void (^)(void))block {
    BOOL didSet = YES; // Set to NO if the current state does not allow it.
    [_lock lock];
    if(block == NULL) { // XXX HACKY Unconditionally allow this since because the code that sets the supers completion block will call this method with NULL once finished.
        [super setCompletionBlock:nil];
    } else {
        if((!(((_state & AFOperationStateMask) == AFOperationReadyState) && ((_state & AFOperationCancelledFlag) == 0)))) { didSet = NO; }
        else {
            __block id _blockSelf = self;
            [super setCompletionBlock:^ {
                block();
                [_blockSelf setCompletionBlock:nil];
            }];
        }
    }
    [_lock unlock];
    if(didSet == NO) { [NSException raise:NSInvalidArgumentException format:@"Property can not be changed once the operation has started."]; }
}

- (NSData *)inputBody {
    id returnObject = NULL;
    [_lock lock];
    returnObject = [[_request.HTTPBody retain] autorelease];
    [_lock unlock];
    return(returnObject);
}

- (void)setInputBody:(NSData *)inputBody {
    BOOL didSet = YES; // Set to NO if the current state does not allow it.
    NSException *caughtException = NULL;
    @try {
        [_lock lock];
        if(!(((_state & AFOperationStateMask) == AFOperationReadyState) && ((_state & AFOperationCancelledFlag) == 0))) { didSet = NO; }
        else {
            NSMutableURLRequest *mutableRequest = [[_request mutableCopy] autorelease];
            mutableRequest.HTTPBody = inputBody;
            self.request = mutableRequest;
        }
    }
    @catch(NSException *e) { caughtException = e; }
    [_lock unlock];
    if(caughtException != NULL) { [caughtException raise]; }
    if(didSet == NO) { [NSException raise:NSInvalidArgumentException format:@"Property can not be changed once the operation has started."]; }
}

- (NSInputStream *)inputStream {
    id returnObject = NULL;
    [_lock lock];
    returnObject = [[_request.HTTPBodyStream retain] autorelease];
    [_lock unlock];
    return(returnObject);
}

- (void)setInputStream:(NSInputStream *)inputStream {
    BOOL didSet = YES; // Set to NO if the current state does not allow it.
    NSException *caughtException = NULL;
    @try {
        [_lock lock];
        if(!(((_state & AFOperationStateMask) == AFOperationReadyState) && ((_state & AFOperationCancelledFlag) == 0))) { didSet = NO; }
        else {
            NSMutableURLRequest *mutableRequest = [[_request mutableCopy] autorelease];
            mutableRequest.HTTPBodyStream = inputStream;
            self.request = mutableRequest;
        }
    }
    @catch(NSException *e) { caughtException = e; }
    [_lock unlock];
    if(caughtException != NULL) { [caughtException raise]; }
    if(didSet == NO) { [NSException raise:NSInvalidArgumentException format:@"Property can not be changed once the operation has started."]; }
}

- (NSOutputStream *)outputStream {
    id returnObject = NULL;
    [_lock lock];
    returnObject = [[_outputStream retain] autorelease];
    [_lock unlock];
    return(returnObject);
}

- (void)setOutputStream:(NSOutputStream *)outputStream {
    BOOL didSet = YES; // Set to NO if the current state does not allow it.
    [_lock lock];
    if(!(((_state & AFOperationStateMask) == AFOperationReadyState) && ((_state & AFOperationCancelledFlag) == 0))) { didSet = NO; }
    else {
        if(outputStream != _outputStream) {
            if(_outputStream != NULL) { [_outputStream release]; _outputStream = NULL; }
            _outputStream = [outputStream retain];
        }
    }
    [_lock unlock];
    if(didSet == NO) { [NSException raise:NSInvalidArgumentException format:@"Property can not be changed once the operation has started."]; }
}

- (void)setUploadProgressBlock:(void (^)(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))block {
    BOOL didSet = YES; // Set to NO if the current state does not allow it.
    [_lock lock];
    if(!(((_state & AFOperationStateMask) == AFOperationReadyState) && ((_state & AFOperationCancelledFlag) == 0))) { didSet = NO; }
    else {
        self.uploadProgress = block;
    }
    [_lock unlock];
    if(didSet == NO) { [NSException raise:NSInvalidArgumentException format:@"Property can not be changed once the operation has started."]; }
}

- (void)setDownloadProgressBlock:(void (^)(NSInteger bytesRead, NSInteger totalBytesRead, NSInteger totalBytesExpectedToRead))block {
    BOOL didSet = YES; // Set to NO if the current state does not allow it.
    [_lock lock];
    if(!(((_state & AFOperationStateMask) == AFOperationReadyState) && ((_state & AFOperationCancelledFlag) == 0))) { didSet = NO; }
    else {
        self.downloadProgress = block;
    }
    [_lock unlock];
    if(didSet == NO) { [NSException raise:NSInvalidArgumentException format:@"Property can not be changed once the operation has started."]; }
}

- (NSString *)responseString {
    BOOL didSet = NO;
    [_lock lock];
    if (!_responseString && _response && _responseData) {
        NSString         *textEncodingName = _response.textEncodingName;
        CFStringEncoding textEncoding      = (textEncodingName == NULL) ? kCFStringEncodingISOLatin1 : CFStringConvertIANACharSetNameToEncoding((CFStringRef)textEncodingName);      
        _responseString = (NSString *)CFStringCreateWithBytes(NULL, (const UInt8 *)_responseData.bytes, (CFIndex)_responseData.length, textEncoding, YES);
        didSet = YES;
    }
    [_lock unlock];

    // _responseString holds the string built above.
    // _responseStringVisibleToKVO holds the KVO visible version.
    // This hackery is needed to get around potential deadlocks when dealing with KVO.
    // This solution allows KVO to pick up the old value and the new value without potentially causing cross thread deadlock issues.

    if(didSet == YES) {
        [self willChangeValueForKey:@"responseString"];
        _responseStringVisibleToKVO = _responseString; // Because didSet and _responseString are set while the lock is held, didSet will be set to YES once, and ONLY once.  This is what makes it safe to do a "naked" assign here.
        [self didChangeValueForKey:@"responseString"];
    }

    [_lock lock];
    NSString *returnResponseString = [[_responseStringVisibleToKVO retain] autorelease];
    [_lock unlock];

    return returnResponseString;
}

#pragma mark - NSOperation

/*
 af_tryToTransitionToState() is used to make sure that only legal state transitions happen in an atomic, thread safe way.
 
 This function uses a NSRecursiveLock (AFURLConnectionOperation class ivar _lock) to ensure that a state transition happens EXACTLY once, and ONCE ONLY.
 
 Allowed transitions:
 
 When Ready or Executing    | When Uninitialized or Finished
 ---------------------------|-------------------------------
 Not Cancelled -> Cancelled | (intentionally left blank)
 
 When Not Cancelled                   | When Cancelled
 -------------------------------------|---------------------------
 Uninitialized -> Ready               | Uninitialized -> Ready
 Ready         -> Executing, Finished | Ready         -> Finished
 Executing     -> Finished            | Executing     -> Finished
 
 The `toState` argument contains the state to transition to, and the `setCancelled` argument is used to transition from Not Cancelled to Cancelled.
 NOTE: If `setCancelled` is `YES`, the value of `toState` is ignored.
 IMPORTANT: `toState & AFOperationStateMask` MUST be equal to `0` (i.e., you can not set state bits via `toState`).
 
 `oldStatePtr` and `newStatePtr` allow the caller to retrieve the before and after values of the atomic mutation.
 
 Returns `YES` if the requested state transition occured, `NO` otherwise.
 */

static BOOL af_tryToTransitionToState(AFURLConnectionOperation *operation, NSUInteger toState, BOOL setCancelled, NSUInteger *oldStatePtr, NSUInteger *newStatePtr) {
    NSCParameterAssert((operation != NULL) && (operation->_lock != NULL) && ((toState & ~AFOperationStateMask) == 0) && ((toState >= AFOperationMinState) && (toState <= AFOperationMaxState)));
    NSUInteger oldState = NSUIntegerMax, newState = NSUIntegerMax;
    
    [operation->_lock lock];
    
    oldState = operation->_state;
    newState = oldState;
    
    // One, but not both, of the following can be changed during a single call to af_tryToTransitionToState():
    // 1: Try to set the cancelled flag.
    // 2: Try to transiation to a new state.
    // This is to help simplify the logic in making sure we only make legal atomic state transitions.
    
    if(setCancelled == YES) {
        if((((oldState & AFOperationStateMask)     == AFOperationReadyState) || ((oldState & AFOperationStateMask) == AFOperationExecutingState)) &&
            ((oldState & AFOperationCancelledFlag) == 0)) { newState |= AFOperationCancelledFlag; }
    } else {
        switch (oldState & AFOperationStateMask) {
            case AFOperationUninitializedState: switch (toState) { // From Uninitialized, only to Ready is allowed.
                case AFOperationReadyState:                 newState  = (oldState & ~AFOperationStateMask) | toState; break;   // Allowed
                default:                                                                                              break;   // Forbidden
            } break;
            case AFOperationReadyState:         switch (toState) { // From Ready to either Executing or Finished is allowed, unless cancelled.
                case AFOperationExecutingState:             if((oldState & AFOperationCancelledFlag) != 0)          { break; } // Not allowed if the cancelled flag is set.
                case AFOperationFinishedState:              newState  = (oldState & ~AFOperationStateMask) | toState; break;   // Allowed
                default:                                                                                              break;   // Forbidden
            } break;
            case AFOperationExecutingState:     switch (toState) { // From Executing, only to Finished is allowed.
                case AFOperationFinishedState:              newState  = (oldState & ~AFOperationStateMask) | toState; break;   // Allowed
                default:                                                                                              break;   // Forbidden
            } break;
                
            default:                                                                                                  break;   // Forbidden
        }
    }
    
    operation->_state = newState; // newState is set to the value of operation->_state once we have the lock and newState is only mutated when a valid transition occurs.
    [operation->_lock unlock];
    NSCParameterAssert(((oldState & AFOperationStateMask) >= AFOperationMinState) && ((oldState & AFOperationStateMask) <= AFOperationMaxState) && ((oldState & ~(AFOperationStateMask | AFOperationStateValidFlags)) == 0));
    NSCParameterAssert(((newState & AFOperationStateMask) >= AFOperationMinState) && ((newState & AFOperationStateMask) <= AFOperationMaxState) && ((newState & ~(AFOperationStateMask | AFOperationStateValidFlags)) == 0));
    
    if(oldStatePtr != NULL) { *oldStatePtr = oldState; }
    if(newStatePtr != NULL) { *newStatePtr = newState; }
    
    return((oldState != newState) ? YES : NO);
}

- (BOOL)isReady
{
    return(([super isReady] && ((_stateVisibleToKVO & AFOperationStateMask) == AFOperationReadyState)) ? YES : NO);
}

- (BOOL)isExecuting
{
    return(((_stateVisibleToKVO & AFOperationStateMask) == AFOperationExecutingState) ? YES : NO);
}

- (BOOL)isFinished
{
    return(((_stateVisibleToKVO & AFOperationStateMask) == AFOperationFinishedState) ? YES : NO);
}

- (BOOL)isCancelled
{
    return((_stateVisibleToKVO & AFOperationCancelledFlag) ? YES : NO);
}

- (void)start {
    NSUInteger oldState = 0, newState = 0;
    BOOL didTransitionState = af_tryToTransitionToState(self, AFOperationExecutingState, NO, &oldState, &newState);

    [self willChangeValueForKey:@"isExecuting"];
    if(didTransitionState == YES) { OSAtomicCompareAndSwapLong(oldState, newState, (volatile long *)&_stateVisibleToKVO); }
    [self didChangeValueForKey:@"isExecuting"];

    if(didTransitionState == NO) { [self finish]; return; }

    [[NSNotificationCenter defaultCenter] postNotificationName:AFNetworkingOperationDidStartNotification object:self];

    [self performSelector:@selector(operationDidStart) onThread:[[self class] networkRequestThread] withObject:nil waitUntilDone:YES];
}


- (void)operationDidStart {
    if([NSThread currentThread] != [[self class] networkRequestThread]) { [self performSelector:@selector(operationDidStart) onThread:[[self class] networkRequestThread] withObject:NULL waitUntilDone:NO]; return; }
    
    BOOL shouldReallyStart = NO;

    [_lock lock];
    if((_state & (AFOperationStateMask | AFOperationCancelledFlag)) == AFOperationExecutingState) { shouldReallyStart = YES; }
    [_lock unlock];
    
    if (shouldReallyStart == NO) {
        [self finish];
        return;
    }
    
    if(_connection != NULL) { [_connection cancel]; [_connection release]; _connection = NULL; } // XXX This really should never happen... but just in case.
    _connection = [[NSURLConnection alloc] initWithRequest:_request delegate:self startImmediately:NO]; // XXX Assumes that this is the only place where this is set, and is safe to do so without the lock due to the above checks.

    _lastUpdateTime = [NSDate timeIntervalSinceReferenceDate];
    
    OSSpinLockLock(&_networkRequestThreadSpinLock);
    NSValue *valueObject = [NSValue valueWithNonretainedObject:self];
#ifndef NS_BLOCK_ASSERTIONS
    BOOL containsOp = [_networkRequestThreadExecutingRequestsSet containsObject:valueObject];
#endif
    [_networkRequestThreadExecutingRequestsSet addObject:valueObject];
    OSSpinLockUnlock(&_networkRequestThreadSpinLock);
    
#ifndef NS_BLOCK_ASSERTIONS
    if(containsOp == YES) { NSLog(@"WARNING: The network threads executing requests set contained this operation in %@!", NSStringFromSelector(_cmd)); }
#endif
    
    [[self class] startNetworkRequestPeriodicTimerIfNeeded];
    
    [_connection start];
}

- (void)finish {
    NSUInteger oldState = 0, newState = 0;
    BOOL didTransitionState = af_tryToTransitionToState(self, AFOperationFinishedState, NO, &oldState, &newState);
    
    [self willChangeValueForKey:@"isFinished"];
    if(didTransitionState == YES) { OSAtomicCompareAndSwapLong(oldState, newState, (volatile long *)&_stateVisibleToKVO); }
    [self didChangeValueForKey:@"isFinished"];

    if(didTransitionState == YES) {
        OSSpinLockLock(&_networkRequestThreadSpinLock);
        [_networkRequestThreadExecutingRequestsSet removeObject:[NSValue valueWithNonretainedObject:self]];
        OSSpinLockUnlock(&_networkRequestThreadSpinLock);

        if (_outputStream) { [_outputStream close]; }
        [_connection cancel];

        [[NSNotificationCenter defaultCenter] postNotificationName:AFNetworkingOperationDidFinishNotification object:self];
    }
}

- (void)cancel
{
    NSUInteger oldState = 0, newState = 0;
    BOOL didTransitionState = af_tryToTransitionToState(self, 0, YES, &oldState, &newState);
    
    [self willChangeValueForKey:@"isCancelled"];
    if(didTransitionState == YES) { OSAtomicCompareAndSwapLong(oldState, newState, (volatile long *)&_stateVisibleToKVO); }
    [self didChangeValueForKey:@"isCancelled"];

    if(((didTransitionState == YES) && (newState & AFOperationStateMask) == AFOperationExecutingState)) {
        [super cancel];
        
        [_connection cancel];

        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        [userInfo setValue:NSLocalizedString(@"The request was cancelled before it was finished", nil) forKey:NSLocalizedDescriptionKey];
        [userInfo setValue:[self.request URL] forKey:NSURLErrorFailingURLErrorKey];

        // We must send this delegate protcol message ourselves since the above [_connection cancel] causes _connection to never send another message to its delegate.
        [self connection:_connection didFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:userInfo]]; 
    }
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
    _lastUpdateTime = [NSDate timeIntervalSinceReferenceDate];

    self.response = (NSHTTPURLResponse *)response;
    
    if (_outputStream) {
        [_outputStream open];
    } else {
        NSUInteger maxCapacity = MAX((NSUInteger)llabs(response.expectedContentLength), kAFHTTPMinimumInitialDataCapacity);
        NSUInteger capacity = MIN(maxCapacity, kAFHTTPMaximumInitialDataCapacity);
        self.dataAccumulator = [NSMutableData dataWithCapacity:capacity];
    }
}

- (void)connection:(NSURLConnection *)__unused connection 
    didReceiveData:(NSData *)data 
{    
    _lastUpdateTime = [NSDate timeIntervalSinceReferenceDate];
    
    self.totalBytesRead += [data length];
    
    if (_outputStream) {
        if ([_outputStream hasSpaceAvailable]) {
            const uint8_t *dataBuffer = [data bytes];
            [self.outputStream write:&dataBuffer[0] maxLength:[data length]];
        }
    } else {
        [_dataAccumulator appendData:data];
    }
    
    if (self.downloadProgress) {
        self.downloadProgress([data length], self.totalBytesRead, (NSInteger)_response.expectedContentLength);
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)__unused connection {        
    _lastUpdateTime = [NSDate timeIntervalSinceReferenceDate];
    
    if (_outputStream) {
        [_outputStream close];
    } else {
        self.responseData = _dataAccumulator; // Note: self.responseData = _dataAccumulator RETAINS _dataAccumulator, not COPIES (i.e., _responseData will point to a NSMutableData, and not an immutable copy).
                                              // Standard Cocoa convention requires that whatever accesses self.responseData treat it as its declared type: An immutable NSData.
        [_dataAccumulator release]; _dataAccumulator = nil;
    }
    
    [self finish];
}

- (void)connection:(NSURLConnection *)__unused connection 
  didFailWithError:(NSError *)error 
{      
    _lastUpdateTime = [NSDate timeIntervalSinceReferenceDate];

    self.error = error;
    
    if (_outputStream) {
        [_outputStream close];
    } else {
        [_dataAccumulator release]; _dataAccumulator = nil;
    }
    
    [self finish];
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
