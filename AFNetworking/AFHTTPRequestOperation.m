// AFHTTPOperation.m
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

#import "AFHTTPRequestOperation.h"

@interface AFHTTPRequestOperation ()
- (BOOL)hasContent;
@property (readwrite, nonatomic, retain) NSError *error;
@end

@implementation AFHTTPRequestOperation
@synthesize acceptableStatusCodes = _acceptableStatusCodes;
@synthesize acceptableContentTypes = _acceptableContentTypes;
@synthesize error = _HTTPError;

- (id)initWithRequest:(NSURLRequest *)request {
    self = [super initWithRequest:request];
    if (!self) {
        return nil;
    }
    
    self.acceptableStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
    
    return self;
}

- (void)dealloc {
    [_acceptableStatusCodes release];
    [_acceptableContentTypes release];
    [_HTTPError release];
    [super dealloc];
}

- (NSHTTPURLResponse *)response {
    return (NSHTTPURLResponse *)[super response];
}

- (NSError *)error {
    if (self.response) {
        if (![self hasAcceptableStatusCode]) {
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
            [userInfo setValue:[NSString stringWithFormat:NSLocalizedString(@"Expected status code %@, got %d", nil), self.acceptableStatusCodes, [self.response statusCode]] forKey:NSLocalizedDescriptionKey];
            [userInfo setValue:[self.request URL] forKey:NSURLErrorFailingURLErrorKey];
            
            self.error = [[[NSError alloc] initWithDomain:AFNetworkingErrorDomain code:NSURLErrorBadServerResponse userInfo:userInfo] autorelease];
        } else if ([self hasContent] && ![self hasAcceptableContentType]) { // Don't invalidate content type if there is no content
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
            [userInfo setValue:[NSString stringWithFormat:NSLocalizedString(@"Expected content type %@, got %@", nil), self.acceptableContentTypes, [self.response MIMEType]] forKey:NSLocalizedDescriptionKey];
            [userInfo setValue:[self.request URL] forKey:NSURLErrorFailingURLErrorKey];
            
            self.error = [[[NSError alloc] initWithDomain:AFNetworkingErrorDomain code:NSURLErrorCannotDecodeContentData userInfo:userInfo] autorelease];
        }
    }
    
    return _HTTPError;
}

- (BOOL)hasContent {
    return [self.responseData length] > 0 && [self.response statusCode] != 204;
}

- (BOOL)hasAcceptableStatusCode {
    return !self.acceptableStatusCodes || [self.acceptableStatusCodes containsIndex:[self.response statusCode]];
}

- (BOOL)hasAcceptableContentType {
    return !self.acceptableContentTypes || [self.acceptableContentTypes containsObject:[self.response MIMEType]];
}

#pragma mark - AFHTTPClientOperation

+ (BOOL)canProcessRequest:(NSURLRequest *)request {
    return NO;
}

+ (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                                    success:(void (^)(id object))success 
                                                    failure:(void (^)(NSHTTPURLResponse *response, NSError *error))failure
{
    return nil;
}        

@end
