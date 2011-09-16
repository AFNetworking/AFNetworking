// AFXMLRequestOperation.h

#import "AFHTTPRequestOperation.h"

@interface AFXMLRequestOperation : AFHTTPRequestOperation

+ (id)operationWithRequest:(NSURLRequest *)urlRequest                
                   success:(void (^)(id XML))success;

+ (id)operationWithRequest:(NSURLRequest *)urlRequest 
                   success:(void (^)(id XML))success
                   failure:(void (^)(NSError *error))failure;

+ (id)operationWithRequest:(NSURLRequest *)urlRequest
     acceptableStatusCodes:(NSIndexSet *)acceptableStatusCodes
    acceptableContentTypes:(NSSet *)acceptableContentTypes
                   success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, id XML))success
                   failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure;

+ (NSIndexSet *)defaultAcceptableStatusCodes;
+ (NSSet *)defaultAcceptableContentTypes;

@end
