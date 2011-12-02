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


@interface AFHTTPRequestOperation ()
@property (readwrite, nonatomic, retain) NSError *HTTPError;
@property (readonly, nonatomic, assign) BOOL hasContent;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
- (void)endBackgroundTask;
#endif
@end

@implementation AFHTTPRequestOperation
@synthesize acceptableStatusCodes = _acceptableStatusCodes;
@synthesize acceptableContentTypes = _acceptableContentTypes;
@synthesize HTTPError = _HTTPError;
@dynamic callbackQueue;
@dynamic responseObject;
@synthesize finishedBlock = _finishedBlock;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
@synthesize attemptToContinueWhenAppEntersBackground=_attemptToContinueWhenAppEntersBackground;
#endif

- (id)initWithRequest:(NSURLRequest *)request {
    self = [super initWithRequest:request];
    if (!self) {
        return nil;
    }
    
    _finishedBlock = nil; 
    _completionBlock = nil;
    self.acceptableStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
    
    //by default we will use the queue that created the request.
    self.callbackQueue = dispatch_get_current_queue();
    
    super.completionBlock = ^ {
        if (_completionBlock) {
            _completionBlock(); //call any child completion blocks that may have been passed in that they may want to run
        }
        
        if ([self isCancelled]) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
            [self endBackgroundTask];
#endif
            self.finishedBlock = nil;
            return;
        }
        
        if (self.finishedBlock) {
            dispatch_async(self.callbackQueue, ^(void) {
                self.finishedBlock();
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
                [self endBackgroundTask];
#endif
                self.finishedBlock = nil;
            });
        } else {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
            [self endBackgroundTask];
#endif
        }
    };
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
    self.attemptToContinueWhenAppEntersBackground = NO;
    _backgroundTask = UIBackgroundTaskInvalid;
#endif
    
    return self;
}

- (void)dealloc {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
    [self endBackgroundTask];
#endif
    
    [_completionBlock release], _completionBlock=nil;
    
    if (_callbackQueue) {
        dispatch_release(_callbackQueue),_callbackQueue=NULL;
    }
    
    [_acceptableStatusCodes release];
    [_acceptableContentTypes release];
    [_HTTPError release];
    [_finishedBlock release], _finishedBlock = nil;
    [super dealloc];
}

- (NSHTTPURLResponse *)response {
    return (NSHTTPURLResponse *)[super response];
}

- (NSError *)error {
    if (self.response && !self.HTTPError) {
        if (![self hasAcceptableStatusCode]) {
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
            [userInfo setValue:[NSString stringWithFormat:NSLocalizedString(@"Expected status code %@, got %d", nil), self.acceptableStatusCodes, [self.response statusCode]] forKey:NSLocalizedDescriptionKey];
            [userInfo setValue:[self.request URL] forKey:NSURLErrorFailingURLErrorKey];
            
            self.HTTPError = [[[NSError alloc] initWithDomain:AFNetworkingErrorDomain code:NSURLErrorBadServerResponse userInfo:userInfo] autorelease];
        } else if ([self hasContent] && ![self hasAcceptableContentType]) { // Don't invalidate content type if there is no content
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
            [userInfo setValue:[NSString stringWithFormat:NSLocalizedString(@"Expected content type %@, got %@", nil), self.acceptableContentTypes, [self.response MIMEType]] forKey:NSLocalizedDescriptionKey];
            [userInfo setValue:[self.request URL] forKey:NSURLErrorFailingURLErrorKey];
            
            self.HTTPError = [[[NSError alloc] initWithDomain:AFNetworkingErrorDomain code:NSURLErrorCannotDecodeContentData userInfo:userInfo] autorelease];
        }
    }
    
    if (_HTTPError) {
        return [[_HTTPError retain] autorelease];
    } else {
        return [super error];
    }
}

- (BOOL)hasContent {
    return [self.responseData length] > 0;
}

- (BOOL)hasAcceptableStatusCode {
    return !self.acceptableStatusCodes || [self.acceptableStatusCodes containsIndex:[self.response statusCode]];
}

- (BOOL)hasAcceptableContentType {
    return !self.acceptableContentTypes || [self.acceptableContentTypes containsObject:[self.response MIMEType]];
}

#pragma mark - iOSMultitasking support 

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
- (void)endBackgroundTask {
    if (_backgroundTask != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:_backgroundTask];
        _backgroundTask = UIBackgroundTaskInvalid;
    }
}

//override 
- (void) start {
    if (![self isReady]) {
        return;
    }
    if (self.attemptToContinueWhenAppEntersBackground){
        if (_backgroundTask != UIBackgroundTaskInvalid) {
            [self endBackgroundTask];
        }
        
        BOOL multiTaskingSupported = NO;
        if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]) {
            multiTaskingSupported = [[UIDevice currentDevice] isMultitaskingSupported];
        }
        
        if (multiTaskingSupported && _attemptToContinueWhenAppEntersBackground) {
            _backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
                if (_backgroundTask != UIBackgroundTaskInvalid)
                {
                    [self cancel];
                    [[UIApplication sharedApplication] endBackgroundTask:_backgroundTask];
                    _backgroundTask = UIBackgroundTaskInvalid;
                }
            }];
        }
    }
    [super start];
}

- (void)cancel {
    [super cancel];
    [self endBackgroundTask];
}
#endif


#pragma mark - AFHTTPClientOperation

+ (BOOL)canProcessRequest:(NSURLRequest *)request {
    return YES;
}

- (void)setCompletionBlock:(void (^)(void))block
{
    if (block != _completionBlock){
        [_completionBlock release];
        _completionBlock = [block copy];
    }
}

- (dispatch_queue_t)callbackQueue {
    return _callbackQueue;
}

- (void) setCallbackQueue:(dispatch_queue_t)callbackQueue {
    if (_callbackQueue == callbackQueue) 
        return;
    
    if (_callbackQueue)
        dispatch_release(_callbackQueue);
    
    if (callbackQueue){
        dispatch_retain(callbackQueue);
        _callbackQueue = callbackQueue;
    }
}

- (id) responseObject {
    //default implementation returns the raw data.
    return [self responseData];
}

@end
