// AFJSONRequestOperation.m
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

#import "AFJSONRequestOperation.h"
#import "JSONKit.h"

@implementation AFJSONRequestOperation

+ (id)operationWithRequest:(NSURLRequest *)urlRequest                
                   success:(void (^)(id JSON))success
{
    return [self operationWithRequest:urlRequest success:success failure:nil];
}

+ (id)operationWithRequest:(NSURLRequest *)urlRequest 
                   success:(void (^)(id JSON))success
                   failure:(void (^)(NSError *error))failure
{    
    return [self operationWithRequest:urlRequest acceptableStatusCodes:[self defaultAcceptableStatusCodes] acceptableContentTypes:[self defaultAcceptableContentTypes] success:success failure:failure];
}

+ (id)operationWithRequest:(NSURLRequest *)urlRequest
     acceptableStatusCodes:(NSIndexSet *)acceptableStatusCodes
    acceptableContentTypes:(NSSet *)acceptableContentTypes
                   success:(void (^)(id JSON))success
                   failure:(void (^)(NSError *error))failure
{
    return [self operationWithRequest:urlRequest completion:^(NSURLRequest *request, NSHTTPURLResponse *response, NSData *data, NSError *error) {        
        BOOL statusCodeAcceptable = [acceptableStatusCodes containsIndex:[response statusCode]];
        BOOL contentTypeAcceptable = [acceptableContentTypes containsObject:[response MIMEType]];
        if (!statusCodeAcceptable || !contentTypeAcceptable) {
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
            [userInfo setValue:[NSHTTPURLResponse localizedStringForStatusCode:[response statusCode]] forKey:NSLocalizedDescriptionKey];
            [userInfo setValue:[request URL] forKey:NSURLErrorFailingURLErrorKey];
            
            error = [[[NSError alloc] initWithDomain:NSURLErrorDomain code:[response statusCode] userInfo:userInfo] autorelease];
        }
        
        if (error) {
            if (failure) {
                failure(error);
            }
        } else {
            id JSON = nil;
            
            Class NSJSONSerialization = NSClassFromString(@"NSJSONSerialization");
            if (NSJSONSerialization) {
                JSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            } else {
                JSON = [[JSONDecoder decoder] objectWithData:data error:&error];
            }             
            
            if (error) {
                if (failure) {
                    failure(error);
                }
            } else {
                if (success) {
                    success(JSON);
                }
            }
        }
    }];
}

+ (NSIndexSet *)defaultAcceptableStatusCodes {
    return [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
}

+ (NSSet *)defaultAcceptableContentTypes {
    return [NSSet setWithObjects:@"application/json", @"application/x-javascript", @"text/javascript", @"text/x-javascript", @"text/x-json", @"text/json", @"text/plain", nil];
}

@end
