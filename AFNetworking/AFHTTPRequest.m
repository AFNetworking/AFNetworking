//
//  AFHTTPRequest.m
//  
//
//  Created by Peter Meyers on 1/13/14.
//
//

#import "AFHTTPRequest.h"
#import "AFHTTPSessionManager.h"

@implementation AFHTTPRequest

+ (NSURLSessionDataTask *) URL:(NSString *)URLString
                    parameters:(NSDictionary *)params
                       success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                       failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
{
    NSAssert([self class] != [AFHTTPRequest class], @"AFHTTPRequest is an abstract class. Please subclass");

    NSURLRequest *request = [[self class] requestWithURL:URLString parameters:params];
    
    NSURLSessionDataTask *task = [[self class] dataTaskWithRequest:request
                                                           success:success
                                                           failure:failure];
    [task resume];
   
    return task;
}

+ (NSURLRequest *) requestWithURL:(NSString *)URLString parameters:(NSDictionary *)parameters
{
    NSURL *url = [NSURL URLWithString:URLString relativeToURL:[AFHTTPSessionManager manager].baseURL];
    
    NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:url];
    
    NSString *httpMethod = NSStringFromClass([self class]);
    
    [mutableRequest setHTTPMethod:httpMethod];
    
    NSURLRequest *request = [[AFHTTPSessionManager manager].requestSerializer requestBySerializingRequest:mutableRequest
                                                                                           withParameters:parameters
                                                                                                    error:nil];
    return request;
}


+ (NSURLSessionDataTask *) dataTaskWithRequest:(NSURLRequest *)request
                                       success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                                       failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
{
    __block NSURLSessionDataTask *task = [[AFHTTPSessionManager manager] dataTaskWithRequest:request
                                                                           completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error)
    {
        if (error) {
            if (failure)
                failure(task, error);
        } else {
            if (success)
                success(task, responseObject);
        }
    }];
    return task;
}


@end

#pragma mark - HTTP Method Subclasses

@implementation GET
@end

@implementation HEAD
@end

@implementation POST

+ (NSURLSessionDataTask *)URL:(NSString *)URLString
                    parameters:(NSDictionary *)params
     constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
                       success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                       failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
{
    NSURLRequest *request = [[AFHTTPSessionManager manager].requestSerializer multipartFormRequestWithMethod:NSStringFromClass([POST class])
                                                                                                   URLString:URLString
                                                                                                  parameters:params
                                                                                   constructingBodyWithBlock:block
                                                                                                       error:nil];
    NSURLSessionDataTask *task = [[self class] dataTaskWithRequest:request
                                                           success:success
                                                           failure:failure];
    [task resume];
    
    return task;
}

@end

@implementation PATCH
@end

@implementation PUT
@end

@implementation DELETE
@end
