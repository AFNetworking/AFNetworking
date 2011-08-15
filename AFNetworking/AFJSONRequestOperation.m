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
#import "JSONKit.h"

#include <Availability.h>

static dispatch_queue_t af_json_request_operation_processing_queue;
static dispatch_queue_t json_request_operation_processing_queue() {
    if (af_json_request_operation_processing_queue == NULL) {
        af_json_request_operation_processing_queue = dispatch_queue_create("com.alamofire.json-request.processing", 0);
    }
    
    return af_json_request_operation_processing_queue;
}

@implementation AFJSONRequestOperation

+ (id)operationWithRequest:(NSURLRequest *)urlRequest                
                   success:(void (^)(id JSON))success
{
    return [self operationWithRequest:urlRequest success:success failure:nil];
}

+ (id)operationWithRequest:(NSURLRequest *)urlRequest 
                   success:(void (^)(id JSON))success
                   failure:(void (^)(NSError *error))failure
{    
    return [self operationWithRequest:urlRequest acceptableStatusCodes:[self defaultAcceptableStatusCodes] acceptableContentTypes:[self defaultAcceptableContentTypes] success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        if (success) {
            success(JSON);
        }
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

+ (id)operationWithRequest:(NSURLRequest *)urlRequest
     acceptableStatusCodes:(NSIndexSet *)acceptableStatusCodes
    acceptableContentTypes:(NSSet *)acceptableContentTypes
                   success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, id JSON))success
                   failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure
{
    return [self operationWithRequest:urlRequest completion:^(NSURLRequest *request, NSHTTPURLResponse *response, NSData *data, NSError *error) {        
        BOOL statusCodeAcceptable = [acceptableStatusCodes containsIndex:[response statusCode]];
        BOOL contentTypeAcceptable = [acceptableContentTypes containsObject:[response MIMEType]];
        if (!statusCodeAcceptable || !contentTypeAcceptable) {
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
            [userInfo setValue:[NSHTTPURLResponse localizedStringForStatusCode:[response statusCode]] forKey:NSLocalizedDescriptionKey];
            [userInfo setValue:[request URL] forKey:NSURLErrorFailingURLErrorKey];
            
            error = [[[NSError alloc] initWithDomain:NSURLErrorDomain code:[response statusCode] userInfo:userInfo] autorelease];
        }
        
        if (error) {
            if (failure) {
                failure(request, response, error);
            }
        } else if ([data length] == 0) {
            if (success) {
                success(request, response, nil);
            }
        } else {
            dispatch_async(json_request_operation_processing_queue(), ^(void) {
                id JSON = nil;
                NSError *JSONError = nil;
#if __IPHONE_OS_VERSION_MIN_REQUIRED > __IPHONE_4_3
                if ([NSJSONSerialization class]) {
                    JSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:&JSONError];
                } else {
                    JSON = [[JSONDecoder decoder] objectWithData:data error:&JSONError];
                }
#else
                JSON = [[JSONDecoder decoder] objectWithData:data error:&JSONError];
#endif
                
                dispatch_sync(dispatch_get_main_queue(), ^(void) {
                    if (JSONError) {
                        if (failure) {
                            failure(request, response, JSONError);
                        }
                    } else {
                        if (success) {
                            success(request, response, JSON);
                        }
                    }
                });
            });
        }
    }];
}

+ (NSIndexSet *)defaultAcceptableStatusCodes {
    return [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
}

+ (NSSet *)defaultAcceptableContentTypes {
    return [NSSet setWithObjects:@"application/json", @"application/x-javascript", @"text/javascript", @"text/x-javascript", @"text/x-json", @"text/json", @"text/plain", nil];
}

@end
