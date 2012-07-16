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
#import "AFJSONUtilities.h"

static dispatch_queue_t af_json_request_operation_processing_queue;
static dispatch_queue_t json_request_operation_processing_queue() {
    if (af_json_request_operation_processing_queue == NULL) {
        af_json_request_operation_processing_queue = dispatch_queue_create("com.alamofire.networking.json-request.processing", 0);
    }
    
    return af_json_request_operation_processing_queue;
}

@interface AFJSONRequestOperation ()
#ifdef AF_ARC_SUPPORT_ENABLED
@property (readwrite, nonatomic, strong) id responseJSON;
@property (readwrite, nonatomic, strong) NSError *JSONError;
#else
@property (readwrite, nonatomic, retain) id responseJSON;
@property (readwrite, nonatomic, retain) NSError *JSONError;
#endif
@end

@implementation AFJSONRequestOperation
@synthesize responseJSON = _responseJSON;
@synthesize JSONError = _JSONError;

+ (AFJSONRequestOperation *)JSONRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                                    success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, id JSON))success 
                                                    failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON))failure
{
#ifdef AF_ARC_SUPPORT_ENABLED
    AFJSONRequestOperation *requestOperation = [[self alloc] initWithRequest:urlRequest];
#else
    AFJSONRequestOperation *requestOperation = [[[self alloc] initWithRequest:urlRequest] autorelease];
#endif
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(operation.request, operation.response, responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(operation.request, operation.response, error, [(AFJSONRequestOperation *)operation responseJSON]);
        }
    }];
    
    return requestOperation;
}

#ifndef AF_ARC_SUPPORT_ENABLED
- (void)dealloc {
    [_responseJSON release];
    [_JSONError release];
    [super dealloc];
}
#endif

- (id)responseJSON {
    if (!_responseJSON && [self.responseData length] > 0 && [self isFinished] && !self.JSONError) {
        NSError *error = nil;

        if ([self.responseData length] == 0) {
            self.responseJSON = nil;
        } else {
            self.responseJSON = AFJSONDecode(self.responseData, &error);
        }
        
        self.JSONError = error;
    }
    
    return _responseJSON;
}

- (NSError *)error {
    if (_JSONError) {
        return _JSONError;
    } else {
        return [super error];
    }
}

#pragma mark - AFHTTPRequestOperation

+ (NSSet *)acceptableContentTypes {
    return [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", nil];
}

+ (BOOL)canProcessRequest:(NSURLRequest *)request {
    return [[[request URL] pathExtension] isEqualToString:@"json"] || [super canProcessRequest:request];
}

- (void)setCompletionBlockWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                              failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
#ifdef AF_ARC_SUPPORT_ENABLED
    static AFJSONRequestOperation *bself = nil;
    bself = self;
#else
    AFJSONRequestOperation *bself = self;
#endif
    
    self.completionBlock = ^ {
        if ([bself isCancelled]) {
            return;
        }
        
        if (bself.error) {
            if (failure) {
                dispatch_async(bself.failureCallbackQueue ? bself.failureCallbackQueue : dispatch_get_main_queue(), ^{
                    failure(bself, bself.error);
                });
            }
        } else {
            dispatch_async(json_request_operation_processing_queue(), ^{
                id JSON = bself.responseJSON;
                
                if (bself.JSONError) {
                    if (failure) {
                        dispatch_async(bself.failureCallbackQueue ? bself.failureCallbackQueue : dispatch_get_main_queue(), ^{
                            failure(bself, bself.error);
                        });
                    }
                } else {
                    if (success) {
                        dispatch_async(bself.successCallbackQueue ? bself.successCallbackQueue : dispatch_get_main_queue(), ^{
                            success(bself, JSON);
                        });
                    }                    
                }
            });
        }
    };
}

@end
