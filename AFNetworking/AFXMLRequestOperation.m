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
#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED
@property (readwrite, nonatomic, retain) NSXMLDocument *responseXMLDocument;
#endif
@property (readwrite, nonatomic, retain) NSError *error;

+ (NSSet *)defaultAcceptableContentTypes;
+ (NSSet *)defaultAcceptablePathExtensions;
@end

@implementation AFXMLRequestOperation
@synthesize responseXMLParser = _responseXMLParser;
#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED
@synthesize responseXMLDocument = _responseXMLDocument;
#endif
@synthesize error = _XMLError;

+ (AFXMLRequestOperation *)XMLParserRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                                        success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSXMLParser *XMLParser))success
                                                        failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure
{
    AFXMLRequestOperation *operation = [[[self alloc] initWithRequest:urlRequest] autorelease];
    operation.completionBlock = ^ {
        if ([operation isCancelled]) {
            return;
        }
    
        if (operation.error) {
            if (failure) {
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    failure(operation.request, operation.response, operation.error);
                });
            }
        } else {
            NSXMLParser *XMLParser = operation.responseXMLParser;
            if (success) {
                success(operation.request, operation.response, XMLParser);
            }
        }
    };
    
    return operation;
}

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
    
#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED
    [_responseXMLDocument release];
#endif
    
    [_XMLError release];
    
    [super dealloc];
}

- (NSXMLParser *)responseXMLParser {
    if (!_responseXMLParser && [self isFinished]) {
        self.responseXMLParser = [[[NSXMLParser alloc] initWithData:self.responseData] autorelease];
    }
    
    return _responseXMLParser;
}

#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED
- (NSXMLDocument *)responseXMLDocument {
    if (!_responseXMLDocument && [self isFinished]) {
        NSError *error = nil;
        self.responseXMLDocument = [[[NSXMLDocument alloc] initWithData:self.responseData options:0 error:&error] autorelease];
        self.error = error;
    }
    
    return _responseXMLDocument;
}
#endif

#pragma mark - NSOperation

- (void)cancel {
    [super cancel];
    
    self.responseXMLParser.delegate = nil;
}

#pragma mark - AFHTTPClientOperation

+ (BOOL)canProcessRequest:(NSURLRequest *)request {
    return [[self defaultAcceptableContentTypes] containsObject:[request valueForHTTPHeaderField:@"Accept"]] || [[self defaultAcceptablePathExtensions] containsObject:[[request URL] pathExtension]];
}

+ (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                                    success:(void (^)(id object))success 
                                                    failure:(void (^)(NSHTTPURLResponse *response, NSError *error))failure
{
    return [self XMLParserRequestOperationWithRequest:urlRequest success:^(NSURLRequest __unused *request, NSHTTPURLResponse __unused *response, NSXMLParser *XMLParser) {
        success(XMLParser);
    } failure:^(NSURLRequest __unused *request, NSHTTPURLResponse *response, NSError *error) {
        failure(response, error);
    }];
}

@end
