//
//  AFHTTPRequest.h
//  
//
//  Created by Peter Meyers on 1/13/14.
//
//

#import <Foundation/Foundation.h>
#import "AFURLRequestSerialization.h"

/**
 `AFHTTPRequest` is an abstract base class for GET, HEAD, POST, PATCH, PUT, DELETE, which creates an HTTP request using the corresponding HTTP method,
    then starts a NSURLSessionDataTask with that request.
 */

@interface AFHTTPRequest : NSObject

- (instancetype) init __attribute__((unavailable("AFHTTPRequest is not intended to be initialized")));

/**
 Creates and runs an `NSURLSessionDataTask` with the HTTP verb that corresponds to the subclass used.
 
 @param URLString The URL string used to create the request URL.
 @param params The parameters to be encoded according to the request serializer of [AFHTTPSessionManager manager].
 @param success A block object to be executed when the task finishes successfully. This block has no return value and takes a single arguments: the data task.
 @param failure A block object to be executed when the task finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes a two arguments: the data task and the error describing the network or parsing error that occurred.
 
 @see -dataTaskWithRequest:completionHandler:
 */

+ (NSURLSessionDataTask *) URL:(NSString *)URLString
                    parameters:(NSDictionary *)params
                       success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                       failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure;

@end

#pragma mark - HTTP Method Subclasses

@interface GET		: AFHTTPRequest
@end

@interface HEAD		: AFHTTPRequest
@end

@interface POST		: AFHTTPRequest

/**
 Creates and runs an `NSURLSessionDataTask` with a multipart `POST` request.
 
 @param URLString The URL string used to create the request URL.
 @param params The parameters to be encoded according to the client request serializer.
 @param block A block that takes a single argument and appends data to the HTTP body. The block argument is an object adopting the `AFMultipartFormData` protocol.
 @param success A block object to be executed when the task finishes successfully. This block has no return value and takes two arguments: the data task, and the response object created by the client response serializer.
 @param failure A block object to be executed when the task finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes a two arguments: the data task and the error describing the network or parsing error that occurred.
 
 @see -dataTaskWithRequest:completionHandler:
 */

+ (NSURLSessionDataTask *)URL:(NSString *)URLString
                   parameters:(NSDictionary *)params
    constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
                      success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                      failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure;

@end

@interface PATCH	: AFHTTPRequest
@end

@interface PUT		: AFHTTPRequest
@end

@interface DELETE	: AFHTTPRequest
@end
