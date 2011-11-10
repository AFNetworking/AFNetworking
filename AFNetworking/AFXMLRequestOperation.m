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
+ (NSSet *)defaultAcceptableContentTypes;
+ (NSSet *)defaultAcceptablePathExtensions;
@end

@implementation AFXMLRequestOperation
@synthesize responseXMLParser = _responseXMLParser;

+ (AFXMLRequestOperation *)XMLParserRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                                        success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSXMLParser *XMLParser))success
                                                        failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, NSXMLParser *XMLParser))failure
{
    
    AFXMLRequestOperation *requestOperation = [[[self alloc] initWithRequest:urlRequest] autorelease];
    //need to really split this class up.
    requestOperation.responseProcessedBlock = ^{
        if (requestOperation.error){
            if (failure) {
                failure(requestOperation.request, requestOperation.response, requestOperation.error, requestOperation.responseXMLParser);
            }
        }
        else
        {
            if (success) {
                success(requestOperation.request, requestOperation.response, requestOperation.responseXMLParser);
            }
        }
        
    };
    
    return requestOperation;
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
    
    self.responseProcessedBlock = ^{
        if (self.error) {
            if (self.failureBlock) {
                self.failureBlock(self,self.error);
            }
        }
        else {
            if (self.successBlock) {
                self.successBlock(self,self.responseXMLParser);
            }
        }
    };
    
    return self;
}

- (void)dealloc {
    [_responseXMLParser release];    
    [super dealloc];
}

- (void)processResponse {
    if (!_responseXMLParser && [self isFinished]) {
        self.responseXMLParser = [[[NSXMLParser alloc] initWithData:self.responseData] autorelease];
    }
}

- (NSXMLParser *)responseXMLParser {
    return _responseXMLParser;
}

#pragma mark - NSOperation

- (void)cancel {
    [super cancel];
    
    self.responseXMLParser.delegate = nil;
}

+ (BOOL)canProcessRequest:(NSURLRequest *)request {
    return [[self defaultAcceptableContentTypes] containsObject:[request valueForHTTPHeaderField:@"Accept"]] || [[self defaultAcceptablePathExtensions] containsObject:[[request URL] pathExtension]];
}

@end
