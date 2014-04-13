//  AFProtocolBufferSessionManager.m
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

#import "AFProtocolBuffersSessionManager.h"


@implementation AFProtocolBufferSessionManager

- (NSURLSessionDataTask *)send:(NSString*)URLString
                       request:(PBGeneratedMessage*)request
                      response:(Class)ResponseClass
                       success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                       failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
{
    [self send:request token:nil request:request response:ResponseClass success:success failure:failure];
}


- (NSURLSessionDataTask *)send:(NSString*)URLString
                         token:(NSString*)token
                       request:(PBGeneratedMessage*)request
                      response:(Class)ResponseClass
                       success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                       failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
{
    NSParameterAssert(URLString);
    NSParameterAssert(request);
    NSParameterAssert(ResponseClass);
    
    NSURL *url = [NSURL URLWithString:URLString relativeToURL:self.baseURL];
    
    NSParameterAssert(url);
    
    if (!self.responseSerializer)
    {
        self.responseSerializer = [AFHTTPResponseSerializer serializer];
    }
    NSMutableSet * contentTypes = self.responseSerializer.acceptableContentTypes.mutableCopy;
    [contentTypes addObject:@"application/x-protobuf"];
    self.responseSerializer.acceptableContentTypes = contentTypes;
    
    // Serializers are used because serializer are a session manager-level properties. With Protocol Buffers every endpoint needs unique request and response serializer.
    NSMutableURLRequest *mutableRequest = [[NSMutableURLRequest alloc] initWithURL:url];
    mutableRequest.HTTPMethod = @"POST"; // all protobufs are posts
    mutableRequest.allowsCellularAccess = YES;
    mutableRequest.cachePolicy = NSURLRequestReloadIgnoringCacheData;
    mutableRequest.HTTPShouldHandleCookies = NO;
    mutableRequest.HTTPShouldUsePipelining = YES;
    [mutableRequest setValue:@"application/x-protobuf" forHTTPHeaderField:@"Content-Type"];
	
    if (token)
    {
        NSString * tokenValue = [NSString stringWithFormat:@"Token token=\"%@\"", token];
        [mutableRequest setValue:tokenValue forHTTPHeaderField:@"Authorization"];
    }
    
    mutableRequest.HTTPBody = request.data;
    
    
    // Drop back into the standard AFNetworking process
    __block NSURLSessionDataTask *task;
    void (^complete)(NSURLResponse * __unused, id, NSError *) = ^(NSURLResponse * __unused response, id responseObject, NSError *error)
    {
        if (error) {
            if (failure) {
                failure(task, error);
            }
        } else {
            if (success) {
                PBGeneratedMessage * result = (PBGeneratedMessage *)[ResponseClass parseFromData:(NSData*)responseObject];
                success(task, (id)result);
            }
        }
    };
    
    [(AFURLSessionManager*)task dataTaskWithRequest:mutableRequest completionHandler:complete];
    
    [task resume];
    
    return task;
}

@end


