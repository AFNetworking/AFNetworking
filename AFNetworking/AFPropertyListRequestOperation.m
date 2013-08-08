// AFPropertyListRequestOperation.m
//
// Copyright (c) 2013 AFNetworking (http://afnetworking.com)
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

#import "AFSerialization.h"

@interface AFPropertyListRequestOperation ()
@property (readwrite, nonatomic, strong) id responsePropertyList;
@property (readwrite, nonatomic, assign) NSPropertyListFormat responsePropertyListFormat;
@property (readwrite, nonatomic, strong) NSError *error;
@property (readwrite, nonatomic, strong) NSRecursiveLock *lock;
@end

@implementation AFPropertyListRequestOperation
@dynamic error;
@dynamic lock;

+ (instancetype)propertyListRequestOperationWithRequest:(NSURLRequest *)request
												success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, id propertyList))success
												failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id propertyList))failure
{
    AFPropertyListRequestOperation *requestOperation = [(AFPropertyListRequestOperation *)[self alloc] initWithRequest:request];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(operation.request, operation.response, responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(operation.request, operation.response, error, [(AFPropertyListRequestOperation *)operation responsePropertyList]);
        }
    }];

    return requestOperation;
}

- (instancetype)initWithRequest:(NSURLRequest *)urlRequest {
    self = [super initWithRequest:urlRequest];
    if (!self) {
        return nil;
    }

    self.responseSerializer = [AFPropertyListSerializer serializerWithFormat:NSPropertyListXMLFormat_v1_0 readOptions:NSPropertyListImmutable writeOptions:0];

    return self;
}

#pragma mark AFPropertyListRequestOperation

- (NSPropertyListReadOptions)propertyListReadOptions {
    return [(AFPropertyListSerializer *)self.responseSerializer readOptions];
}

- (void)setPropertyListReadOptions:(NSPropertyListReadOptions)propertyListReadOptions {
    [self.lock lock];
    if (self.propertyListReadOptions != propertyListReadOptions) {
        [(AFPropertyListSerializer *)self.responseSerializer setReadOptions:propertyListReadOptions];

        self.responsePropertyList = nil;
    }
    [self.lock unlock];
}

- (id)responsePropertyList {
    [self.lock lock];
    if (!_responsePropertyList && [self.responseData length] > 0 && [self isFinished]) {
        NSPropertyListFormat format;
        NSError *error = nil;
        self.responsePropertyList = [NSPropertyListSerialization propertyListWithData:self.responseData options:self.propertyListReadOptions format:&format error:&error];
        self.responsePropertyListFormat = format;
        self.error = error;
    }
    [self.lock unlock];

    return _responsePropertyList;
}

#pragma mark - AFHTTPRequestOperation

- (void)setCompletionBlockWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                              failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    __weak __typeof(self)weakSelf = self;
    [super setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        if (![responseObject isKindOfClass:[NSData class]]) {
            [strongSelf setResponsePropertyList:responseObject];
        }

        if (success) {
            success(operation, responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf setError:error];

        if (failure) {
            failure(operation, error);
        }
    }];
}

@end
