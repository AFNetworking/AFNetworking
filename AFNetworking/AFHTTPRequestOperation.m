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
#import "AFNetworkActivityIndicatorManager.h"

typedef enum {
    AFHTTPOperationReadyState       = 1,
    AFHTTPOperationExecutingState   = 2,
    AFHTTPOperationFinishedState    = 3,
    AFHTTPOperationCancelledState   = 4,
} AFHTTPOperationState;

NSString * const AFHTTPOperationDidStartNotification = @"com.alamofire.http-operation.start";
NSString * const AFHTTPOperationDidFinishNotification = @"com.alamofire.http-operation.finish";

typedef void (^AFHTTPRequestOperationProgressBlock)(NSUInteger totalBytesWritten, NSUInteger totalBytesExpectedToWrite);
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
    if (from == to) {
        return NO;
    }
    
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
@property (nonatomic, assign) AFHTTPOperationState state;
@property (nonatomic, assign) BOOL isCancelled;
@property (readwrite, nonatomic, retain) NSMutableData *dataAccumulator;
@property (readwrite, nonatomic, copy) AFHTTPRequestOperationProgressBlock progress;
@property (readwrite, nonatomic, copy) AFHTTPRequestOperationCompletionBlock completion;

- (void)cleanup;
@end

@implementation AFHTTPRequestOperation
@synthesize state = _state;
@synthesize isCancelled = _isCancelled;
@synthesize connection = _connection;
@synthesize runLoopModes = _runLoopModes;
@synthesize request = _request;
@synthesize response = _response;
@synthesize error = _error;
@synthesize responseBody = _responseBody;
@synthesize dataAccumulator = _dataAccumulator;
@synthesize progress = _progress;
@synthesize completion = _completion;

+ (id)operationWithRequest:(NSURLRequest *)urlRequest 
                completion:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSData *data, NSError *error))completion
{
    AFHTTPRequestOperation *operation = [[[self alloc] initWithRequest:urlRequest] autorelease];
    operation.completion = completion;
    
    return operation;
}

- (id)initWithRequest:(NSURLRequest *)urlRequest {
    self = [super init];
    if (!self) {
		return nil;
    }
        
    self.request = urlRequest;
	
    self.runLoopModes = [NSSet setWithObjects:NSRunLoopCommonModes, nil];
        
    self.state = AFHTTPOperationReadyState;
	
    return self;
}

- (void)dealloc {
    [_runLoopModes release];
    
    [_request release];
    [_response release];
    [_responseBody release];
    [_dataAccumulator release];
    
    [_connection release];
	
    [_progress release];
    [_completion release];
    [super dealloc];
}

- (void)cleanup {
    for (NSString *runLoopMode in self.runLoopModes) {
        [self.connection unscheduleFromRunLoop:[NSRunLoop currentRunLoop] forMode:runLoopMode];
    }
    CFRunLoopStop([[NSRunLoop currentRunLoop] getCFRunLoop]); 
}

- (void)setProgressBlock:(void (^)(NSUInteger totalBytesWritten, NSUInteger totalBytesExpectedToWrite))block {
    self.progress = block;
}

- (void)setState:(AFHTTPOperationState)state {
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
    
    switch (state) {
        case AFHTTPOperationExecutingState:
            [[AFNetworkActivityIndicatorManager sharedManager] startAnimating];
            [[NSNotificationCenter defaultCenter] postNotificationName:AFHTTPOperationDidStartNotification object:self];
            break;
        case AFHTTPOperationFinishedState:
            [[AFNetworkActivityIndicatorManager sharedManager] stopAnimating];
            [[NSNotificationCenter defaultCenter] postNotificationName:AFHTTPOperationDidFinishNotification object:self];
            [self cleanup];
            break;
        default:
            break;
    }
}

- (NSString *)responseString {
    return [[[NSString alloc] initWithData:self.responseBody encoding:NSUTF8StringEncoding] autorelease];
}

#pragma mark - NSOperation

- (BOOL)isReady {
    return self.state == AFHTTPOperationReadyState;
}

- (BOOL)isExecuting {
    return self.state == AFHTTPOperationExecutingState;
}

- (BOOL)isFinished {
    return self.state == AFHTTPOperationFinishedState || [self isCancelled];
}

- (BOOL)isConcurrent {
    return YES;
}

- (void)start {
    if (self.isFinished) {
        return;
    }
    
    self.state = AFHTTPOperationExecutingState;
        
    self.connection = [[[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO] autorelease];
    
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    for (NSString *runLoopMode in self.runLoopModes) {
        [self.connection scheduleInRunLoop:runLoop forMode:runLoopMode];
    }
    
    [self.connection start];

    [runLoop run];
}

- (void)cancel {
    self.isCancelled = YES;
    
    [self.connection cancel];
    
    [self cleanup];
}

#pragma mark - AFHTTPRequestOperation

- (void)finish {
    if (self.isCancelled) {
        return;
    }
    
    if (self.completion) {
        self.completion(self.request, self.response, self.responseBody, self.error);
    }
}

#pragma mark - NSURLConnection

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.response = (NSHTTPURLResponse *)response;
    NSUInteger contentLength = MIN(MAX(abs(response.expectedContentLength), 1024), 1024 * 1024 * 8);

    self.dataAccumulator = [NSMutableData dataWithCapacity:contentLength];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[self.dataAccumulator appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    self.state = AFHTTPOperationFinishedState;
    
    self.responseBody = [NSData dataWithData:self.dataAccumulator];
    self.dataAccumulator = nil;

    [self performSelectorOnMainThread:@selector(finish) withObject:nil waitUntilDone:NO];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {  
    self.state = AFHTTPOperationFinishedState;
    
    self.error = error;
    
    [self performSelectorOnMainThread:@selector(finish) withObject:nil waitUntilDone:NO];
}

- (void)connection:(NSURLConnection *)connection 
   didSendBodyData:(NSInteger)bytesWritten 
 totalBytesWritten:(NSInteger)totalBytesWritten 
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    if (self.progress) {
        self.progress(totalBytesWritten, totalBytesExpectedToWrite);
    }
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    if ([self isCancelled]) {
        return nil;
    }
    
    return cachedResponse;
}

@end
