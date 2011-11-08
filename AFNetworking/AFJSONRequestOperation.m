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
#import "AFJSONUtilities.h"

@interface AFJSONRequestOperation ()
@property (readwrite, nonatomic, retain) id responseJSON;
@property (readwrite, nonatomic, retain) NSError *JSONError;

+ (NSSet *)defaultAcceptableContentTypes;
+ (NSSet *)defaultAcceptablePathExtensions;

@end

@implementation AFJSONRequestOperation
@synthesize responseJSON = _responseJSON;
@synthesize JSONError = _JSONError;


+ (AFJSONRequestOperation *)JSONRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                                    success:(void (^)(NSURLRequest *request, NSURLResponse *response, id JSON))successs
                                                    failure:(void (^)(NSURLRequest *request, NSURLResponse *response, NSError *error, id JSON))failure
{
    AFJSONRequestOperation *requestOperation = [[[self alloc] initWithRequest:urlRequest] autorelease];
    operation.successBlock = success; // have move these kinds of properties up
    operation.failureBlock = failure; 

    return requestOperation;
}

+ (id)alloc
{
    if ([AFJSONRequestOperation self] == self)
        return [AFNETWORKING_DEFAULT_JSON_OPERATION alloc];
    else
        return [super alloc];
}

+ (id)allocWithZone:(NSZone *)zone
{
    if ([AFJSONRequestOperation self] == self)
        return [AFNETWORKING_DEFAULT_JSON_OPERATION allocWithZone:zone];
    else
        return [super allocWithZone:zone];
}

+ (NSSet *)defaultAcceptableContentTypes {
    return [NSSet setWithObjects:@"application/json", @"text/json", nil];
}

+ (NSSet *)defaultAcceptablePathExtensions {
    return [NSSet setWithObjects:@"json", nil];
}

+ (BOOL)canProcessRequest:(NSURLRequest *)request {
    return [[self defaultAcceptableContentTypes] containsObject:[request valueForHTTPHeaderField:@"Accept"]] || [[self defaultAcceptablePathExtensions] containsObject:[[request URL] pathExtension]];
}

- (id)initWithRequest:(NSURLRequest *)urlRequest {
    
    self = [super initWithRequest:urlRequest];
    if (!self) {
        return nil;
    }
    
    self.acceptableContentTypes = [[self class] defaultAcceptableContentTypes];
    
    return self;
}

- (void)dealloc {
    [_responseJSON release];
    [_JSONError release];
    [super dealloc];
}

- (void)processResponse {    
    if (!_responseJSON && [self isFinished]) {
        NSError *error = nil;

        if ([self.responseData length] == 0) {
            self.responseJSON = nil;
        } else {
            self.responseJSON = AFJSONDecode(self.responseData, &error);
        }
        self.JSONError = error;
    }
}
                                                    
+ (id) decodeJSONObjectWithData:(NSData *)data error:(NSError **)error {
    //implement me in the subclass
    [self doesNotRecognizeSelector: _cmd];
    return nil;
}

+ (NSString *)JSONStringWithDictionary:(NSDictionary *)dictionary {
    [self doesNotRecognizeSelector: _cmd];
    return nil;
}



- (NSError *)error {
    if (_JSONError) {
        return _JSONError;
    } else {
        return [super error];
    }
}

- (void)setCompletionBlockWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                              failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    self.completionBlock = ^ {
        if ([self isCancelled]) {
            return;
        }
        
        if (self.error) {
            if (failure) {
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    failure(self, self.error);
                });
            }
        } else {
            dispatch_async(json_request_operation_processing_queue(), ^(void) {
                id JSON = self.responseJSON;
                
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    if (self.JSONError) {
                        if (failure) {
                            failure(self, self.JSONError);
                        }
                    } else {
                        if (success) {
                            success(self, JSON);
                        }
                    }
                }); 
            });
        }
    };    
}

@end

#ifdef AF_INCLUDE_FOUNDATIONJSON
@implementation AFFoundationJSONRequestOperation

+ (id) decodeJSONObjectWithData:(NSData *)data error:(NSError **)error {
    if ([data length] == 0) {
        return nil;
    } else {
        return [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
    }
}


+ (NSString *)JSONStringWithDictionary:(NSDictionary *)dictionary {
    NSError *error = nil;
    NSData *JSONData = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:&error];
    if (!error) {
        return [[[NSString alloc] initWithData:JSONData encoding:NSUTF8StringEncoding] autorelease];
    }
    return nil;
}

@end
#endif

#ifdef AF_INCLUDE_JSONKIT
#import "JSONKit.h"

@implementation AFJSONKitJSONRequestOperation

+ (id) decodeJSONObjectWithData:(NSData *)data error:(NSError **)error {
    if ([data length] == 0) {
        return nil;
    } else {
        return [[JSONDecoder decoder] objectWithData:data error:error];
    }
}

+ (NSString *)JSONStringWithDictionary:(NSDictionary *)dictionary {
    return [dictionary JSONString];
}


@end
#endif

