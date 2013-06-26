// UIWebView+AFNetworking.m
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

#import "UIWebView+AFNetworking.h"

#import "AFHTTPRequestOperation.h"

#import <objc/runtime.h>

static char kAFHTTPRequestOperationKey;

@interface UIWebView (_AFNetworking)
@property (readwrite, nonatomic, strong, setter = af_setHTTPRequestOperation:) AFHTTPRequestOperation *af_HTTPRequestOperation;
@end

@implementation UIWebView (_AFNetworking)
@dynamic af_HTTPRequestOperation;
@end

#pragma mark -

@implementation UIWebView (AFNetworking)

- (AFHTTPRequestOperation *)af_HTTPRequestOperation {
    return (AFHTTPRequestOperation *)objc_getAssociatedObject(self, &kAFHTTPRequestOperationKey);
}

- (void)af_setHTTPRequestOperation:(AFHTTPRequestOperation *)operation {
    objc_setAssociatedObject(self, &kAFHTTPRequestOperationKey, operation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark -

- (void)loadRequest:(NSURLRequest *)request
           progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
            success:(NSString * (^)(NSHTTPURLResponse *response, NSString *HTML))success
            failure:(void (^)(NSError *error))failure
{
    if (self.af_HTTPRequestOperation) {
        [self.af_HTTPRequestOperation cancel];
    }

    self.af_HTTPRequestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    __weak __typeof(self)weakSelf = self;
    [self.af_HTTPRequestOperation setDownloadProgressBlock:progress];
    [self.af_HTTPRequestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *HTML = success ? success(operation.response, operation.responseString) : operation.responseString;
        [weakSelf loadHTMLString:HTML baseURL:[operation.response URL]];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
    [self.af_HTTPRequestOperation start];
}

@end
