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

#import "JSONKit.h"

static dispatch_queue_t af_json_request_operation_processing_queue;
static dispatch_queue_t json_request_operation_processing_queue() {
    if (af_json_request_operation_processing_queue == NULL) {
        af_json_request_operation_processing_queue = dispatch_queue_create("com.alamofire.networking.json-request.processing", 0);
    }
    
    return af_json_request_operation_processing_queue;
}

@interface AFJSONRequestOperation ()
@property (readwrite, nonatomic, retain) id responseJSON;
@property (readwrite, nonatomic, retain) NSError *JSONError;

+ (NSSet *)defaultAcceptableContentTypes;
+ (NSSet *)defaultAcceptablePathExtensions;
@end

@implementation AFJSONRequestOperation
@synthesize responseJSON = _responseJSON;
@synthesize JSONError = _JSONError;

+ (AFJSONRequestOperation *)JSONRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                                    success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, id JSON))success
                                                    failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure
{
    AFJSONRequestOperation *operation = [[[self alloc] initWithRequest:urlRequest] autorelease];
    operation.completionBlock = ^ {
        if ([operation isCancelled]) {
            return;
        }
        
        if (operation.error) {
            if (failure) {
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    failure(operation.request, operation.response, operation.error);
                });
            }
        } else {
            dispatch_async(json_request_operation_processing_queue(), ^(void) {
                id JSON = operation.responseJSON;
                
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    if (operation.error) {
                        if (failure) {
                            failure(operation.request, operation.response, operation.error);
                        }
                    } else {
                        if (success) {
                            success(operation.request, operation.response, JSON);
                        }
                    }
                }); 
            });
        }
    };
    
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
    
    self.acceptableContentTypes = [[self class] defaultAcceptableContentTypes];
    
    return self;
}

- (void)dealloc {
    [_responseJSON release];
    [_JSONError release];
    [super dealloc];
}

- (id)responseJSON {
    if (!_responseJSON && [self isFinished]) {
        NSError *error = nil;

        if ([self.responseData length] == 0) {
            self.responseJSON = nil;
        } else {

#if __IPHONE_OS_VERSION_MIN_REQUIRED > __IPHONE_4_3 || __MAC_OS_X_VERSION_MIN_REQUIRED > __MAC_10_6
            if ([NSJSONSerialization class]) {
                self.responseJSON = [NSJSONSerialization JSONObjectWithData:self.responseData options:0 error:&error];
            } else {
                self.responseJSON = [[JSONDecoder decoder] objectWithData:self.responseData error:&error];
            }
#else
            self.responseJSON = [[JSONDecoder decoder] objectWithData:self.responseData error:&error];
#endif
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
