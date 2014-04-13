// AFProtocolBufferSessionManager.h
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


#import "AFHTTPSessionManager.h"

#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000) || (defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 1090)

/**
 `AFProtocolBufferSessionManager` is a subclass of `AFHTTPSessionManager` for sending Protocol Buffers over TCP.
 ## Serialization
 
 Serializers are not used because they can not be uniquely set for the each endpoint request/response.
 
 ## Exmaple
 
 NSString * send:urlString = @"/api/user";
 
 UserRequest_Builder * builder = [UserRequest_Builder new];
 builder.email = email;
 builder.password = password;
 
 UserRequest * request = [builder build];
 
 AFProtocolBufferSessionManager * manager = self.sharedManager;
 
 NSURLSessionDataTask * task = [manager send:urlString
 request:request
 response:[UserBesponse class]
 success:success
 failure:failure];
 
*/

@interface AFProtocolBufferSessionManager : AFHTTPSessionManager <NSCoding, NSCopying>

/**
 Creates and runs an `NSURLSessionDataTask` with a `DELETE` request.
 
 @param URLString The URL string used to create the request URL.
 @param request PBGeneratedMessage subclass that is generated from a PBGeneratedMessage_Builder
 @param ResponseClass PBGeneratedMessage subclass that will deserialize the response from the server
 @param success A block object to be executed when the task finishes successfully. This block has no return value and takes two arguments: the data task, and the response object created by the client response serializer.
 @param failure A block object to be executed when the task finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes a two arguments: the data task and the error describing the network or parsing error that occurred.
 
 @see -dataTaskWithRequest:completionHandler:
 */
- (NSURLSessionDataTask *)send:(NSString*)URLString
                       request:(id)request
                      response:(Class)ResponseClass
                       success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                       failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure;

/**
 Creates and runs an `NSURLSessionDataTask` with a `DELETE` request.
 
 @param URLString The URL string used to create the request URL.
 @param token optional token for sending to over SSL
 @param request PBGeneratedMessage subclass that is generated from a PBGeneratedMessage_Builder
 @param ResponseClass PBGeneratedMessage subclass that will deserialize the response from the server
 @param success A block object to be executed when the task finishes successfully. This block has no return value and takes two arguments: the data task, and the response object created by the client response serializer.
 @param failure A block object to be executed when the task finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes a two arguments: the data task and the error describing the network or parsing error that occurred.
 
 @see -dataTaskWithRequest:completionHandler:
 */
- (NSURLSessionDataTask *)send:(NSString*)URLString
                         token:(NSString*)token
                       request:(id)request
                      response:(Class)ResponseClass
                       success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                       failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure;
@end

#endif