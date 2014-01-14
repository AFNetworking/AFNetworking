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
    
    NSURL *url = [NSURL URLWithString:URLString relativeToURL:[AFHTTPSessionManager manager].baseURL];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSString *httpMethod = NSStringFromClass([self class]);
    [request setHTTPMethod:httpMethod];
    
    NSURLRequest *serializedRequest = [[AFHTTPSessionManager manager].requestSerializer requestBySerializingRequest:request
                                                                                                     withParameters:params
                                                                                                              error:nil];
    __block NSURLSessionDataTask *task;
	
    task = [[AFHTTPSessionManager manager] dataTaskWithRequest:serializedRequest
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
    
    [task resume];
    return task;
}

@end

#pragma mark - HTTP Method Subclasses

@implementation GET
@end

@implementation HEAD
@end

@implementation POST
@end

@implementation PATCH
@end

@implementation PUT
@end

@implementation DELETE
@end
