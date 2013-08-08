// AFXMLRequestOperation.m
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

#import "AFXMLRequestOperation.h"
#import "AFSerialization.h"
#include <Availability.h>

@interface AFXMLRequestOperation ()
@property (readwrite, nonatomic, strong) NSXMLParser *responseXMLParser;
#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED
@property (readwrite, nonatomic, strong) AFXMLDocumentSerializer *XMLDocumentSerializer;
@property (readwrite, nonatomic, strong) NSXMLDocument *responseXMLDocument;
#endif
@property (readwrite, nonatomic, strong) NSError *error;
@property (readwrite, nonatomic, strong) NSRecursiveLock *lock;
@end

@implementation AFXMLRequestOperation
@dynamic error;
@dynamic lock;

+ (instancetype)XMLParserRequestOperationWithRequest:(NSURLRequest *)urlRequest
											 success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSXMLParser *XMLParser))success
											 failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, NSXMLParser *XMLParser))failure
{
    AFXMLRequestOperation *requestOperation = [(AFXMLRequestOperation *)[self alloc] initWithRequest:urlRequest];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(operation.request, operation.response, responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(operation.request, operation.response, error, [(AFXMLRequestOperation *)operation responseXMLParser]);
        }
    }];

    return requestOperation;
}

#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED
+ (instancetype)XMLDocumentRequestOperationWithRequest:(NSURLRequest *)urlRequest
											   success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSXMLDocument *document))success
											   failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, NSXMLDocument *document))failure
{
    AFXMLRequestOperation *requestOperation = [[self alloc] initWithRequest:urlRequest];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, __unused id responseObject) {
        if (success) {
            NSXMLDocument *XMLDocument = [(AFXMLRequestOperation *)operation responseXMLDocument];
            success(operation.request, operation.response, XMLDocument);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            NSXMLDocument *XMLDocument = [(AFXMLRequestOperation *)operation responseXMLDocument];
            failure(operation.request, operation.response, error, XMLDocument);
        }
    }];

    return requestOperation;
}
#endif

- (instancetype)initWithRequest:(NSURLRequest *)urlRequest {
    self = [super initWithRequest:urlRequest];
    if (!self) {
        return nil;
    }

    self.responseSerializer = [AFXMLParserSerializer serializer];

#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED
    self.XMLDocumentSerializer = [AFXMLDocumentSerializer serializer];
#endif

    return self;
}

#pragma mark - AFXMLRequestOperation

- (NSXMLParser *)responseXMLParser {
    [self.lock lock];
    if (!_responseXMLParser && [self.responseData length] > 0 && [self isFinished]) {
        NSError *error = nil;
        self.responseXMLParser = [self.responseSerializer responseObjectForResponse:self.response data:self.responseData error:&error];
        self.error = error;
    }
    [self.lock unlock];

    return _responseXMLParser;
}

#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED
- (NSUInteger)XMLDocumentOptions {
    return self.XMLDocumentSerializer.options;
}

- (void)setXMLDocumentOptions:(NSUInteger)mask {
    [self.lock lock];
    if (self.XMLDocumentOptions != mask) {
        self.XMLDocumentSerializer.options = mask;

        self.responseXMLDocument = nil;
    }

    [self.lock unlock];
}

- (NSXMLDocument *)responseXMLDocument {
    [self.lock lock];
    if (!_responseXMLDocument && [self.responseData length] > 0 && [self isFinished]) {
        NSError *error = nil;
        self.responseXMLDocument = [self.XMLDocumentSerializer responseObjectForResponse:self.response data:self.responseData error:&error];
        self.error = error;
    }
    [self.lock unlock];

    return _responseXMLDocument;
}
#endif

#pragma mark - AFHTTPRequestOperation

- (void)setCompletionBlockWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                              failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    __weak __typeof(self)weakSelf = self;
    [super setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        if ([responseObject isKindOfClass:[NSXMLParser class]]) {
            [strongSelf setResponseXMLParser:responseObject];
        }

#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED
        if ([responseObject isKindOfClass:[NSXMLDocument class]]) {
            [strongSelf setResponseXMLDocument:responseObject];
        }
#endif

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

#pragma mark - NSOperation

- (void)cancel {
    [super cancel];

    self.responseXMLParser.delegate = nil;
}

@end
