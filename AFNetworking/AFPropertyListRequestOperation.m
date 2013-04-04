// AFPropertyListRequestOperation.m
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

#import "AFPropertyListRequestOperation.h"

static dispatch_queue_t property_list_request_operation_processing_queue() {
    static dispatch_queue_t af_property_list_request_operation_processing_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        af_property_list_request_operation_processing_queue = dispatch_queue_create("com.alamofire.networking.property-list-request.processing", DISPATCH_QUEUE_CONCURRENT);
    });

    return af_property_list_request_operation_processing_queue;
}

@interface AFPropertyListRequestOperation ()
@property (readwrite, nonatomic, assign) NSPropertyListFormat propertyListFormat;
@end

@implementation AFPropertyListRequestOperation
@synthesize propertyListReadOptions = _propertyListReadOptions;
@synthesize propertyListFormat = _propertyListFormat;

+ (instancetype)propertyListRequestOperationWithRequest:(NSURLRequest *)request
												success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, id propertyList))success
												failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id propertyList))failure
{
    AFPropertyListRequestOperation *requestOperation = [[self alloc] initWithRequest:request];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(operation.request, operation.response, responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(operation.request, operation.response, error, [(AFPropertyListRequestOperation *)operation responseObject]);
        }
    }];

    return requestOperation;
}

- (id)initWithRequest:(NSURLRequest *)urlRequest {
    self = [super initWithRequest:urlRequest];
    if (!self) {
        return nil;
    }

    self.propertyListReadOptions = NSPropertyListImmutable;

    return self;
}

-(void)processResponse {
    if (!self.responseObject && [self.responseData length] > 0 && [self isFinished]) {
        NSPropertyListFormat format;
        NSError *error = nil;
        self.responseObject = [NSPropertyListSerialization propertyListWithData:self.responseData options:self.propertyListReadOptions format:&format error:&error];
        self.propertyListFormat = format;
        self.processingError = error;
    }
}

#pragma mark - AFHTTPRequestOperation

+ (NSSet *)acceptableContentTypes {
    return [NSSet setWithObject:@"application/x-plist"];
}

+ (BOOL)canProcessRequest:(NSURLRequest *)request {
    return [[[request URL] pathExtension] isEqualToString:@"plist"] || [super canProcessRequest:request];
}

@end
