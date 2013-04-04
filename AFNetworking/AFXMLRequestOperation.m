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

static dispatch_queue_t xml_request_operation_processing_queue() {
    static dispatch_queue_t af_xml_request_operation_processing_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        af_xml_request_operation_processing_queue = dispatch_queue_create("com.alamofire.networking.xml-request.processing", DISPATCH_QUEUE_CONCURRENT);
    });

    return af_xml_request_operation_processing_queue;
}

@interface AFXMLRequestOperation ()
#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED
@property (readwrite, nonatomic, strong) NSXMLDocument *responseXMLDocument;
#endif
@end

@implementation AFXMLRequestOperation
#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED
@synthesize responseXMLDocument = _responseXMLDocument;
#endif

+ (instancetype)XMLParserRequestOperationWithRequest:(NSURLRequest *)urlRequest
											 success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSXMLParser *XMLParser))success
											 failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, NSXMLParser *XMLParser))failure
{
    AFXMLRequestOperation *requestOperation = [(AFXMLRequestOperation *)[self alloc] initWithRequest:urlRequest];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(operation.request, operation.response, responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(operation.request, operation.response, error, [(AFXMLRequestOperation *)operation responseObject]);
        }
    }];

    return requestOperation;
}

#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED
+ (instancetype)XMLDocumentRequestOperationWithRequest:(NSURLRequest *)urlRequest
											   success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSXMLDocument *document))success
											   failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, NSXMLDocument *document))failure
{
    AFXMLRequestOperation *requestOperation = [[self alloc] initWithRequest:urlRequest];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, __unused id responseObject) {
        if (success) {
            NSXMLDocument *XMLDocument = [(AFXMLRequestOperation *)operation responseXMLDocument];
            success(operation.request, operation.response, XMLDocument);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            NSXMLDocument *XMLDocument = [(AFXMLRequestOperation *)operation responseXMLDocument];
            failure(operation.request, operation.response, error, XMLDocument);
        }
    }];

    return requestOperation;
}
#endif

-(void) processResponse {
    if (!self.responseObject && [self.responseData length] > 0 && [self isFinished]) {
        self.responseObject = [[NSXMLParser alloc] initWithData:self.responseData];
#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED
        NSError *error = nil;
        self.responseXMLDocument = [[NSXMLDocument alloc] initWithData:self.responseData options:0 error:&error];
        self.processingError = error;
#endif
    }
}

#pragma mark - NSOperation

- (void)cancel {
    [super cancel];

    self.responseObject.delegate = nil;
}

#pragma mark - AFHTTPRequestOperation

+ (NSSet *)acceptableContentTypes {
    return [NSSet setWithObjects:@"application/xml", @"text/xml", nil];
}

+ (BOOL)canProcessRequest:(NSURLRequest *)request {
    return [[[request URL] pathExtension] isEqualToString:@"xml"] || [super canProcessRequest:request];
}

@end
