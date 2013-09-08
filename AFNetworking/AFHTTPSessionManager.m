// AFHTTPClient.m
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

#import <Foundation/Foundation.h>

#import "AFHTTPSessionManager.h"
#import "AFHTTPRequestOperation.h"

#import <Availability.h>
#import <Security/Security.h>

#ifdef _SYSTEMCONFIGURATION_H
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>
#endif

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
#import <UIKit/UIKit.h>
#endif

@interface AFHTTPSessionManager ()
@property (readwrite, nonatomic, strong) NSURL *baseURL;
@end

@implementation AFHTTPSessionManager

+ (instancetype)client {
    return [[AFHTTPSessionManager alloc] initWithBaseURL:nil];
}

- (instancetype)initWithBaseURL:(NSURL *)url {
    return [self initWithBaseURL:url sessionConfiguration:nil];
}

- (instancetype)initWithBaseURL:(NSURL *)url
           sessionConfiguration:(NSURLSessionConfiguration *)configuration
{
    self = [super initWithSessionConfiguration:configuration];
    if (!self) {
        return nil;
    }

    // Ensure terminal slash for baseURL path, so that NSURL +URLWithString:relativeToURL: works as expected
    if ([[url path] length] > 0 && ![[url absoluteString] hasSuffix:@"/"]) {
        url = [url URLByAppendingPathComponent:@""];
    }

    self.baseURL = url;

    self.requestSerializer = [AFJSONRequestSerializer serializer];
    self.responseSerializer = [AFCompoundResponseSerializer compoundSerializerWithResponseSerializers:@[[AFJSONResponseSerializer serializer]]];

    self.securityPolicy = [AFSecurityPolicy defaultPolicy];

    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, baseURL: %@, session: %@, operationQueue: %@>", NSStringFromClass([self class]), self, [self.baseURL absoluteString], self.session, self.operationQueue];
}

#pragma mark -

#ifdef _SYSTEMCONFIGURATION_H
#endif

- (void)setRequestSerializer:(AFHTTPRequestSerializer <AFURLRequestSerialization> *)requestSerializer {
    NSParameterAssert(requestSerializer);

    _requestSerializer = requestSerializer;
}

- (void)setResponseSerializer:(AFHTTPResponseSerializer <AFURLResponseSerialization> *)responseSerializer {
    NSParameterAssert(responseSerializer);

    [super setResponseSerializer:responseSerializer];
}

#pragma mark -

- (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)request
                                                    success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                                    failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = self.responseSerializer;

    [operation setCompletionBlockWithSuccess:success failure:failure];

    return operation;
}

#pragma mark -

- (void)enqueueHTTPRequestOperation:(AFHTTPRequestOperation *)operation {
    [self.operationQueue addOperation:operation];
}

- (void)cancelAllHTTPOperationsWithMethod:(NSString *)method
                                     path:(NSString *)path
{
    [self cancelAllHTTPOperationsWithMethod:method URLString:path];
}

- (void)cancelAllHTTPOperationsWithMethod:(NSString *)method
                                URLString:(NSString *)URLString
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
    NSURL *URLToBeMatched = [[self.requestSerializer requestWithMethod:(method ?: @"GET") URLString:URLString parameters:nil] URL];
#pragma clang diagnostic pop

    for (NSOperation *operation in [self.operationQueue operations]) {
        if (![operation isKindOfClass:[AFHTTPRequestOperation class]]) {
            continue;
        }

        BOOL hasMatchingMethod = !method || [method isEqualToString:[[(AFHTTPRequestOperation *)operation request] HTTPMethod]];
        BOOL hasMatchingURL = [[[(AFHTTPRequestOperation *)operation request] URL] isEqual:URLToBeMatched];

        if (hasMatchingMethod && hasMatchingURL) {
            [operation cancel];
        }
    }
}

- (void)enqueueBatchOfHTTPRequestOperationsWithRequests:(NSArray *)requests
                                          progressBlock:(void (^)(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations))progressBlock
                                        completionBlock:(void (^)(NSArray *operations))completionBlock
{
    NSMutableArray *mutableOperations = [NSMutableArray array];
    for (NSURLRequest *request in requests) {
        AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:nil failure:nil];
        [mutableOperations addObject:operation];
    }

    [self enqueueBatchOfHTTPRequestOperations:mutableOperations progressBlock:progressBlock completionBlock:completionBlock];
}

- (void)enqueueBatchOfHTTPRequestOperations:(NSArray *)operations
                              progressBlock:(void (^)(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations))progressBlock
                            completionBlock:(void (^)(NSArray *operations))completionBlock
{
    __block dispatch_group_t group = dispatch_group_create();
    NSBlockOperation *batchedOperation = [NSBlockOperation blockOperationWithBlock:^{
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            if (completionBlock) {
                completionBlock(operations);
            }
        });
    }];

    for (AFHTTPRequestOperation *operation in operations) {
        operation.completionGroup = group;
        void (^originalCompletionBlock)(void) = [operation.completionBlock copy];
        __weak __typeof(operation)weakOperation = operation;
        operation.completionBlock = ^{
            __strong __typeof(weakOperation)strongOperation = weakOperation;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
            dispatch_queue_t queue = strongOperation.completionQueue ?: dispatch_get_main_queue();
#pragma clang diagnostic pop
            dispatch_group_async(group, queue, ^{
                if (originalCompletionBlock) {
                    originalCompletionBlock();
                }

                NSUInteger numberOfFinishedOperations = [[operations indexesOfObjectsPassingTest:^BOOL(id op, NSUInteger __unused idx,  BOOL __unused *stop) {
                    return [op isFinished];
                }] count];

                if (progressBlock) {
                    progressBlock(numberOfFinishedOperations, [operations count]);
                }

                dispatch_group_leave(group);
            });
        };

        dispatch_group_enter(group);
        [batchedOperation addDependency:operation];
    }
    [self.operationQueue addOperations:operations waitUntilFinished:NO];
    [self.operationQueue addOperation:batchedOperation];
}

#pragma mark -

- (NSURLSessionDataTask *)GET:(NSString *)URLString
                   parameters:(NSDictionary *)parameters
                      success:(void (^)(NSHTTPURLResponse *response, id responseObject))success
                      failure:(void (^)(NSError *error))failure
{
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"GET" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:parameters];

    NSURLSessionDataTask *task = [self dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
            if (failure) {
                failure(error);
            }
        } else {
            if (success) {
                success((NSHTTPURLResponse *)response, responseObject);
            }
        }
    }];

    [task resume];

    return task;
}

- (NSURLSessionDataTask *)HEAD:(NSString *)URLString
                    parameters:(NSDictionary *)parameters
                       success:(void (^)(NSHTTPURLResponse *response))success
                       failure:(void (^)(NSError *error))failure
{
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"HEAD" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:parameters];

    NSURLSessionDataTask *task = [self dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
            if (failure) {
                failure(error);
            }
        } else {
            if (success) {
                success((NSHTTPURLResponse *)response);
            }
        }
    }];

    [task resume];

    return task;
}

- (NSURLSessionDataTask *)POST:(NSString *)URLString
                    parameters:(NSDictionary *)parameters
                       success:(void (^)(NSHTTPURLResponse *response, id responseObject))success
                       failure:(void (^)(NSError *error))failure
{
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"POST" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:parameters];

    NSURLSessionDataTask *task = [self dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
            if (failure) {
                failure(error);
            }
        } else {
            if (success) {
                success((NSHTTPURLResponse *)response, responseObject);
            }
        }
    }];

    [task resume];

    return task;
}

- (NSURLSessionDataTask *)POST:(NSString *)URLString
                    parameters:(NSDictionary *)parameters
     constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
                       success:(void (^)(NSHTTPURLResponse *response, id responseObject))success
                       failure:(void (^)(NSError *error))failure
{
    NSMutableURLRequest *request = [self.requestSerializer multipartFormRequestWithMethod:@"POST" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:parameters constructingBodyWithBlock:block];

    NSURLSessionDataTask *task = [self dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
            if (failure) {
                failure(error);
            }
        } else {
            if (success) {
                success((NSHTTPURLResponse *)response, responseObject);
            }
        }
    }];

    [task resume];

    return task;
}

- (NSURLSessionDataTask *)PUT:(NSString *)URLString
                   parameters:(NSDictionary *)parameters
                      success:(void (^)(NSHTTPURLResponse *response, id responseObject))success
                      failure:(void (^)(NSError *error))failure
{
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"PUT" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:parameters];

    NSURLSessionDataTask *task = [self dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
            if (failure) {
                failure(error);
            }
        } else {
            if (success) {
                success((NSHTTPURLResponse *)response, responseObject);
            }
        }
    }];

    [task resume];

    return task;
}

- (NSURLSessionDataTask *)PATCH:(NSString *)URLString
                     parameters:(NSDictionary *)parameters
                        success:(void (^)(NSHTTPURLResponse *response, id responseObject))success
                        failure:(void (^)(NSError *error))failure
{
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"PATCH" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:parameters];

    NSURLSessionDataTask *task = [self dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
            if (failure) {
                failure(error);
            }
        } else {
            if (success) {
                success((NSHTTPURLResponse *)response, responseObject);
            }
        }
    }];
    
    [task resume];

    return task;
}

- (NSURLSessionDataTask *)DELETE:(NSString *)URLString
                      parameters:(NSDictionary *)parameters
                         success:(void (^)(NSHTTPURLResponse *response, id responseObject))success
                         failure:(void (^)(NSError *error))failure
{
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"DELETE" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:parameters];

    NSURLSessionDataTask *task = [self dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
            if (failure) {
                failure(error);
            }
        } else {
            if (success) {
                success((NSHTTPURLResponse *)response, responseObject);
            }
        }
    }];

    [task resume];

    return task;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    NSURL *baseURL = [aDecoder decodeObjectForKey:@"baseURL"];
    NSURLSessionConfiguration *configuration = [aDecoder decodeObjectForKey:@"sessionConfiguration"];

    self = [self initWithBaseURL:baseURL sessionConfiguration:configuration];
    if (!self) {
        return nil;
    }

    self.requestSerializer = [aDecoder decodeObjectForKey:@"requestSerializer"];
    self.responseSerializer = [aDecoder decodeObjectForKey:@"responseSerializer"];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:self.baseURL forKey:@"baseURL"];
    [aCoder encodeObject:self.requestSerializer forKey:@"requestSerializer"];
    [aCoder encodeObject:self.responseSerializer forKey:@"responseSerializer"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    AFHTTPSessionManager *HTTPClient = [[[self class] allocWithZone:zone] initWithBaseURL:self.baseURL sessionConfiguration:self.session.configuration];

    HTTPClient.requestSerializer = [self.requestSerializer copyWithZone:zone];
    HTTPClient.responseSerializer = [self.responseSerializer copyWithZone:zone];
    
    return HTTPClient;
}

@end
