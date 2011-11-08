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


static dispatch_queue_t af_request_operation_processing_queue;
static dispatch_queue_t request_operation_processing_queue() {
    if (af_request_operation_processing_queue == NULL) {
        af_request_operation_processing_queue = dispatch_queue_create("com.alamofire.networking.request.processing", DISPATCH_QUEUE_CONCURRENT);
    }
    
    return af_request_operation_processing_queue;
}

@interface AFHTTPRequestOperation ()
@property (readwrite, nonatomic, retain) NSError *HTTPError;
@property (readonly, nonatomic, assign) BOOL hasContent;
@end

@implementation AFHTTPRequestOperation
@synthesize acceptableStatusCodes = _acceptableStatusCodes;
@synthesize acceptableContentTypes = _acceptableContentTypes;
@synthesize HTTPError = _HTTPError;
@synthesize responseProcessedBlock = _responseProcessedBlock;
@dynamic callbackQueue;
@synthesize successBlock = _successBlock;
@synthesize failureBlock = _failureBlock;


- (id)initWithRequest:(NSURLRequest *)request {
    self = [super initWithRequest:request];
    if (!self) {
        return nil;
    }
    
    self.acceptableStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
    
    //default implementation
    self.responseProcessedBlock = ^{
        //already in calling queue. no more work to do here
        if (self.error) {
            if (self.failureBlock) {
                self.failureBlock(self,self.error);
            }
        }
        else
        {
            if (self.successBlock) {
                self.successBlock(self,self.responseData);
            }
        }
    };
    
    //by default we will use the queue that created the request.
    self.callbackQueue = dispatch_get_current_queue();
    
    super.completionBlock = ^ {
        if (_completionBlock)
            _completionBlock(); //call any super completion block that may have been passed in.
        
        if ([self isCancelled]) {
            return;
        }
        
        if (self.HTTPError) {
            if (self.responseProcessedBlock) {
                dispatch_async(self.callbackQueue, ^(void) {
                    self.responseProcessedBlock();
                });
            }
        } else {
            dispatch_async(request_operation_processing_queue(), ^(void) {
                [self processResponse];
                dispatch_async(self.callbackQueue, ^(void) {
                    if (self.responseProcessedBlock) {
                        self.responseProcessedBlock();
                    }
                });
            });
        }
    };
    
    return self;
}

- (void)dealloc {
    [_completionBlock release];
    
    if (_callbackQueue) {
        dispatch_release(_callbackQueue),_callbackQueue=NULL;
    }
    
    [_acceptableStatusCodes release];
    [_acceptableContentTypes release];
    [_HTTPError release];
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

- (void)processResponse {
    //this is where subclasses will do all their dirty work
}


@end
