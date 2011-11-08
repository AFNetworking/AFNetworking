// AFXMLRequestOperation.m
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

#import "AFXMLRequestOperation.h"

#include <Availability.h>

@interface AFXMLRequestOperation ()
@property (readwrite, nonatomic, retain) NSXMLParser *responseXMLParser;
#if __MAC_OS_X_VERSION_MIN_REQUIRED
@property (readwrite, nonatomic, retain) NSXMLDocument *responseXMLDocument;
#endif
@property (readwrite, nonatomic, retain) NSError *error;
@property (readwrite, nonatomic, copy) void (^processResponseBlock)(void);
+ (NSSet *)defaultAcceptableContentTypes;
+ (NSSet *)defaultAcceptablePathExtensions;
@end

@implementation AFXMLRequestOperation
@synthesize responseXMLParser = _responseXMLParser;
#if __MAC_OS_X_VERSION_MIN_REQUIRED
@synthesize responseXMLDocument = _responseXMLDocument;
#endif
@synthesize error = _XMLError;
@synthesize processResponseBlock = _processResponseBlock;

+ (AFXMLRequestOperation *)XMLParserRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                                        success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSXMLParser *XMLParser))success
                                                        failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, NSXMLParser *XMLParser))failure
{
    
    AFXMLRequestOperation *requestOperation = [[[self alloc] initWithRequest:urlRequest] autorelease];
    //need to really split this class up.
    requestOperation.processResponseBlock = ^ {
        requestOperation.decodedResponse = requestOperation.responseXMLParser;
    };
    requestOperation.successBlock = success; // have to move these kind of properties up.
    requestOperation.failureBlock = failure;

    AFXMLRequestOperation *requestOperation = [[[self alloc] initWithRequest:urlRequest] autorelease];

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

#if __MAC_OS_X_VERSION_MIN_REQUIRED
+ (AFXMLRequestOperation *)XMLDocumentRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                                          success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSXMLDocument *document))success
                                                          failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, NSXMLDocument *document))failure
{
    AFXMLRequestOperation *operation = [[[self alloc] initWithRequest:urlRequest] autorelease];

    operation.successBlock = success;
    operation.failureBlock = failure;
    operation.processResponseBlock = ^ {
        operation.decodedResponse = operation.responseXMLDocument;
    }
    
    operation.completionBlock = ^ {
        if ([operation isCancelled]) {
            return;
        }
        
        if (operation.error) {
            if (failure) {
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    failure(operation.request, operation.response, operation.error, [(AFXMLRequestOperation *)operation responseXMLDocument]);
                });
            }
        } else {
            dispatch_async(xml_request_operation_processing_queue(), ^(void) {
                NSXMLDocument *XMLDocument = operation.responseXMLDocument;
                if (success) {
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        success(operation.request, operation.response, XMLDocument);
                    });
                }
            });
        }
    };
    
>>>>>>> 206f6ff1f62dde0bf4c57b89a95cb5d790293f43
    return operation;
}
#endif

+ (NSSet *)defaultAcceptableContentTypes {
    return [NSSet setWithObjects:@"application/xml", @"text/xml", nil];
}

+ (NSSet *)defaultAcceptablePathExtensions {
    return [NSSet setWithObjects:@"xml", nil];
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
    _responseXMLParser.delegate = nil;
    [_responseXMLParser release];
    [_processResponseBlock release];
#if __MAC_OS_X_VERSION_MIN_REQUIRED
    [_responseXMLDocument release];
#endif
    
    [_XMLError release];
    
    [super dealloc];
}

- (void)processResponse {
    if (self.processResponseBlock)
    {
        self.processResponseBlock();
    }
}

- (NSXMLParser *)responseXMLParser {
    if (!_responseXMLParser && [self isFinished]) {
        self.responseXMLParser = [[[NSXMLParser alloc] initWithData:self.responseData] autorelease];
    }
    
    return _responseXMLParser;
}

#if __MAC_OS_X_VERSION_MIN_REQUIRED
- (NSXMLDocument *)responseXMLDocument {
    if (!_responseXMLDocument && [self isFinished]) {
        NSError *error = nil;
        self.responseXMLDocument = [[[NSXMLDocument alloc] initWithData:self.responseData options:0 error:&error] autorelease];
        self.error = error;
    }
    
    return _responseXMLDocument;
}
#endif

- (NSError *)error {
    if (_XMLError) {
        return _XMLError;
    } else {
        return [super error];
    }
}

#pragma mark - NSOperation

- (void)cancel {
    [super cancel];
    
    self.responseXMLParser.delegate = nil;
}

+ (BOOL)canProcessRequest:(NSURLRequest *)request {
    return [[self defaultAcceptableContentTypes] containsObject:[request valueForHTTPHeaderField:@"Accept"]] || [[self defaultAcceptablePathExtensions] containsObject:[[request URL] pathExtension]];
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
#if __MAC_OS_X_VERSION_MIN_REQUIRED
            if (success) {
                success(self, self.responseXMLDocument);
            }
#else
<<<<<<< HEAD
    return [self XMLParserRequestOperationWithRequest:urlRequest success:^(NSURLRequest __unused *request, NSHTTPURLResponse __unused *response, id XMLParser) {
        success((NSXMLParser *)XMLParser);
    } failure:^(NSURLRequest __unused *request, NSHTTPURLResponse *response, NSError *error) {
        failure(response, error);
    }];
=======
            if (success) {
                success(self, self.responseXMLParser);
            }
>>>>>>> 206f6ff1f62dde0bf4c57b89a95cb5d790293f43
#endif
        }
    };    
}

@end
