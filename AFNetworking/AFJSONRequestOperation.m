// AFJSONRequestOperation.m
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

#import "AFJSONRequestOperation.h"

#include <Availability.h>

static dispatch_queue_t af_json_request_operation_processing_queue;
static dispatch_queue_t json_request_operation_processing_queue() {
    if (af_json_request_operation_processing_queue == NULL) {
        af_json_request_operation_processing_queue = dispatch_queue_create("com.alamofire.networking.json-request.processing", 0);
    }
    
    return af_json_request_operation_processing_queue;
}

@interface AFJSONRequestOperation ()
@property (readwrite, nonatomic, retain) NSError *error;

+ (NSSet *)defaultAcceptableContentTypes;
+ (NSSet *)defaultAcceptablePathExtensions;

- (void)processJSONResponseWithCompletion:(void (^)(void))complete;

@end

@implementation AFJSONRequestOperation
@synthesize responseJSON = _responseJSON;
@synthesize error = _JSONError;
@synthesize successBlock = _successBlock;
@synthesize failureBlock = _failureBlock;
@dynamic callbackQueue;

+ (AFJSONRequestOperation *)JSONRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                                    success:(AFJSONRequestOperationSuccessBlock)success
                                                    failure:(AFJSONRequestOperationFailureBlock)failure
{
    AFJSONRequestOperation *operation = [[[AFNETWORKING_DEFAULT_JSON_OPERATION alloc] initWithRequest:urlRequest] autorelease];
    operation.successBlock = success;
    operation.failureBlock = failure;
    return operation;
}

+ (NSSet *)defaultAcceptableContentTypes {
    return [NSSet setWithObjects:@"application/json", @"text/json", nil];
}

+ (NSSet *)defaultAcceptablePathExtensions {
    return [NSSet setWithObjects:@"json", nil];
}

- (id)initWithRequest:(NSURLRequest *)urlRequest {
    self = [super initWithRequest:urlRequest];
    if (!self) {
        return nil;
    }
    self.failureBlock = NULL;
    self.successBlock = NULL;
    
    //by default we will use the queue that created the request.
    self.callbackQueue = dispatch_get_current_queue();
    
    self.acceptableContentTypes = [[self class] defaultAcceptableContentTypes];
    
    self.completionBlock = ^ {
        if ([self isCancelled]) {
            return;
        }
        
        if (self.error) {
            if (_failureBlock) {
                dispatch_async(self.callbackQueue, ^(void) {
                    _failureBlock(self.request, self.response, self.error);
                });
            }
        } else {
            [self processJSONResponseWithCompletion:^{
                dispatch_async(self.callbackQueue, ^(void) {
                    if (self.error) {
                        if (_failureBlock) {
                            _failureBlock(self.request, self.response, self.error);
                        }
                    } else {
                        if (_successBlock) {
                            _successBlock(self.request, self.response, self.responseJSON);
                        }
                    }
                }); 
            }];
        }
    };
    
    
    return self;
}

- (void)dealloc {
    [_successBlock release];
    [_failureBlock release];
    [_responseJSON release];
    [_JSONError release];
    
    if (_callbackQueue) {
        dispatch_release(_callbackQueue),_callbackQueue=NULL;
    }
    [super dealloc];
}

- (void)processJSONResponseWithCompletion:(void (^)(void))complete {
    dispatch_async(json_request_operation_processing_queue(), ^(void) {
        [self decodeJSON];
        complete();
    });
}
                                                    
- (void) decodeJSON {
    // implemented by subclasses
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

#pragma mark - AFHTTPClientOperation

+ (BOOL)canProcessRequest:(NSURLRequest *)request {
    return [[self defaultAcceptableContentTypes] containsObject:[request valueForHTTPHeaderField:@"Accept"]] || [[self defaultAcceptablePathExtensions] containsObject:[[request URL] pathExtension]];
}

+ (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                                    success:(void (^)(id object))success 
                                                    failure:(void (^)(NSHTTPURLResponse *response, NSError *error))failure
{
    return [self JSONRequestOperationWithRequest:urlRequest success:^(NSURLRequest __unused *request, NSHTTPURLResponse __unused *response, id JSON) {
        success(JSON);
    } failure:^(NSURLRequest __unused *request, NSHTTPURLResponse *response, NSError *error) {
        failure(response, error);
    }];
}

@end

#ifdef AF_INCLUDE_FOUNDATIONJSON
@implementation AFFoundationJSONRequestOperation

- (void) decodeJSON {
    if (!self.responseJSON && [self isFinished]) {
        NSError *error = nil;
        
        if ([self.responseData length] == 0) {
            self.responseJSON = nil;
        } else {
            self.responseJSON = [NSJSONSerialization JSONObjectWithData:self.responseData options:0 error:&error];
            self.error = error;
        }
    }
}

@end
#endif

#ifdef AF_INCLUDE_JSONKIT
#import "JSONKit.h"

@implementation AFJSONKitJSONRequestOperation

- (void) decodeJSON {
    if (!self.responseJSON && [self isFinished]) {
        NSError *error = nil;
        if ([self.responseData length] == 0) {
            self.responseJSON = nil;
        } else {
            self.responseJSON = [[JSONDecoder decoder] objectWithData:self.responseData error:&error];
            self.error = error;
        }
    }
}

@end
#endif

