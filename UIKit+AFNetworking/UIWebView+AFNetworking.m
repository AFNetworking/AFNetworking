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

#import <objc/runtime.h>

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)

#import "AFHTTPRequestOperation.h"

static char kAFRequestSerializerKey;
static char kAFResponseSerializerKey;
static char kAFHTTPRequestOperationKey;

@interface UIWebView (_AFNetworking)
@property (readwrite, nonatomic, strong, setter = af_setHTTPRequestOperation:) AFHTTPRequestOperation *af_HTTPRequestOperation;
@end

@implementation UIWebView (_AFNetworking)

- (AFHTTPRequestOperation *)af_HTTPRequestOperation {
    return (AFHTTPRequestOperation *)objc_getAssociatedObject(self, &kAFHTTPRequestOperationKey);
}

- (void)af_setHTTPRequestOperation:(AFHTTPRequestOperation *)operation {
    objc_setAssociatedObject(self, &kAFHTTPRequestOperationKey, operation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@interface NSString (AFMIMEAware)

@property (readonly, getter=getEncodingOrUtf8) NSString *encodingOrUtf8;
@property (readonly, getter=getNSEncoding) NSStringEncoding nsEncoding;
@property (readonly, getter=getMimeType) NSString *mimeType;

@end

@implementation NSString (AFMIMEAware)

/**
 * See http://www.w3.org/International/O-HTTP-charset
 */
-(NSString*)getEncodingOrUtf8 {
    NSArray *parts = [self componentsSeparatedByString:@"charset="];
    NSString *charset;
    if ([parts count] == 2) {
      charset = [[parts objectAtIndex:1] lowercaseString];
    }
    return charset != nil ? charset : @"utf-8";
}

/**
 * Convert an IANA character set to a `NSStringEncoding`. If
 * `encodingName` is `nil`, return `NSUTF8StringEncoding` as a guess.
 */
-(NSStringEncoding)getNSEncoding {
    NSString *encName = self.encodingOrUtf8;
    CFStringEncoding cfEnc = CFStringConvertIANACharSetNameToEncoding((CFStringRef)encName);
    return CFStringConvertEncodingToNSStringEncoding(cfEnc);
}

-(NSString*)getMimeType {
    return [[self componentsSeparatedByString:@"; "] objectAtIndex:0];
}

@end

#pragma mark -

@implementation UIWebView (AFNetworking)

- (AFHTTPRequestSerializer <AFURLRequestSerialization> *)requestSerializer {
    static AFHTTPRequestSerializer <AFURLRequestSerialization> * _af_defaultRequestSerializer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _af_defaultRequestSerializer = [AFHTTPRequestSerializer serializer];
    });

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
    return objc_getAssociatedObject(self, &kAFRequestSerializerKey) ?: _af_defaultRequestSerializer;
#pragma clang diagnostic pop
}

- (void)setRequestSerializer:(AFHTTPRequestSerializer<AFURLRequestSerialization> *)requestSerializer {
    objc_setAssociatedObject(self, &kAFRequestSerializerKey, requestSerializer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (AFHTTPResponseSerializer <AFURLResponseSerialization> *)responseSerializer {
    static AFHTTPResponseSerializer <AFURLResponseSerialization> * _af_defaultResponseSerializer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _af_defaultResponseSerializer = [AFHTTPResponseSerializer serializer];
    });

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
    return objc_getAssociatedObject(self, &kAFRequestSerializerKey) ?: _af_defaultResponseSerializer;
#pragma clang diagnostic pop
}

- (void)setResponseSerializer:(AFHTTPResponseSerializer<AFURLResponseSerialization> *)responseSerializer {
    objc_setAssociatedObject(self, &kAFResponseSerializerKey, responseSerializer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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

    request = [self.requestSerializer requestBySerializingRequest:request withParameters:nil error:nil];

    self.af_HTTPRequestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    self.af_HTTPRequestOperation.responseSerializer = self.responseSerializer;
    
    __weak __typeof(self)weakSelf = self;
    [self.af_HTTPRequestOperation setDownloadProgressBlock:progress];
    [self.af_HTTPRequestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id __unused responseObject) {
        NSString *HTML = success ? success(operation.response, operation.responseString) : operation.responseString;
        [weakSelf loadHTMLString:HTML baseURL:[operation.response URL]];
    } failure:^(AFHTTPRequestOperation * __unused operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];

    [self.af_HTTPRequestOperation start];
}

@end

#endif
