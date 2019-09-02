//
//  WkWebView+AFNetworking.m
//  AFNetworking iOS
//
//  Created by Sebastiaan Seegers on 02/09/2019.
//  Copyright © 2019 AFNetworking. All rights reserved.
//

#import "WKWebView+AFNetworking.h"

#import <objc/runtime.h>

#if TARGET_OS_IOS

#import "AFHTTPSessionManager.h"
#import "AFURLResponseSerialization.h"
#import "AFURLRequestSerialization.h"

@interface WKWebView (_AFNetworking)
@property (readwrite, nonatomic, strong, setter = af_setURLSessionTask:) NSURLSessionDataTask *af_URLSessionTask;
@end

@implementation WKWebView (_AFNetworking)

- (NSURLSessionDataTask *)af_URLSessionTask {
    return (NSURLSessionDataTask *)objc_getAssociatedObject(self, @selector(af_URLSessionTask));
}

- (void)af_setURLSessionTask:(NSURLSessionDataTask *)af_URLSessionTask {
    objc_setAssociatedObject(self, @selector(af_URLSessionTask), af_URLSessionTask, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

#pragma mark -

@implementation WKWebView (AFNetworking)

- (AFHTTPSessionManager *)sessionManager {
    static AFHTTPSessionManager *_af_defaultHTTPSessionManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _af_defaultHTTPSessionManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        _af_defaultHTTPSessionManager.requestSerializer = [AFHTTPRequestSerializer serializer];
        _af_defaultHTTPSessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    });
    
    return objc_getAssociatedObject(self, @selector(sessionManager)) ?: _af_defaultHTTPSessionManager;
}

- (void)setSessionManager:(AFHTTPSessionManager *)sessionManager {
    objc_setAssociatedObject(self, @selector(sessionManager), sessionManager, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (AFHTTPResponseSerializer <AFURLResponseSerialization> *)responseSerializer {
    static AFHTTPResponseSerializer <AFURLResponseSerialization> *_af_defaultResponseSerializer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _af_defaultResponseSerializer = [AFHTTPResponseSerializer serializer];
    });
    
    return objc_getAssociatedObject(self, @selector(responseSerializer)) ?: _af_defaultResponseSerializer;
}

- (void)setResponseSerializer:(AFHTTPResponseSerializer<AFURLResponseSerialization> *)responseSerializer {
    objc_setAssociatedObject(self, @selector(responseSerializer), responseSerializer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark -

- (void)loadRequest:(NSURLRequest *)request
           progress:(NSProgress * _Nullable __autoreleasing * _Nullable)progress
            success:(nullable NSString * (^)(NSHTTPURLResponse *response, NSString *HTML))success
            failure:(nullable void (^)(NSError *error))failure {
    [self loadRequest:request MIMEType:nil textEncodingName:nil progress:progress success:^NSData * _Nonnull(NSHTTPURLResponse * _Nonnull response, NSData * _Nonnull data) {
        NSStringEncoding stringEncoding = NSUTF8StringEncoding;
        if (response.textEncodingName) {
            CFStringEncoding encoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)response.textEncodingName);
            if (encoding != kCFStringEncodingInvalidId) {
                stringEncoding = CFStringConvertEncodingToNSStringEncoding(encoding);
            }
        }
        
        NSString *string = [[NSString alloc] initWithData:data encoding:stringEncoding];
        if (success) {
            string = success(response, string);
        }
        
        return [string dataUsingEncoding:stringEncoding];
    } failure:failure];
}

- (void)loadRequest:(NSURLRequest *)request
           MIMEType:(nullable NSString *)MIMEType
   textEncodingName:(nullable NSString *)textEncodingName
           progress:(NSProgress * _Nullable __autoreleasing * _Nullable)progress
            success:(nullable NSData * (^)(NSHTTPURLResponse *response, NSData *data))success
            failure:(nullable void (^)(NSError *error))failure {
    NSParameterAssert(request);
    
    if (self.af_URLSessionTask.state == NSURLSessionTaskStateRunning || self.af_URLSessionTask.state == NSURLSessionTaskStateSuspended) {
        [self.af_URLSessionTask cancel];
    }
    self.af_URLSessionTask = nil;
    
    __weak __typeof(self)weakSelf = self;
    __block NSURLSessionDataTask *dataTask;
    __strong __typeof(weakSelf) strongSelf = weakSelf;
    __strong __typeof(weakSelf.navigationDelegate) strongSelfDelegate = strongSelf.navigationDelegate;
    dataTask = [self.sessionManager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        if (error) {
            if (failure) {
                failure(error);
            }
        } else {
            if (success) {
                success((NSHTTPURLResponse *)response, responseObject);
            }
            [strongSelf loadData:responseObject MIMEType:MIMEType characterEncodingName:textEncodingName baseURL:[dataTask.currentRequest URL]];
            
            if ([strongSelfDelegate respondsToSelector:@selector(webView:didFinishNavigation:)]) {
                [strongSelfDelegate webView:strongSelf didFinishNavigation:strongSelfDelegate];
            }
        }
    }];
    self.af_URLSessionTask = dataTask;
    if (progress != nil) {
        *progress = [self.sessionManager downloadProgressForTask:dataTask];
    }
    [self.af_URLSessionTask resume];
    
    if ([strongSelfDelegate respondsToSelector:@selector(webView:didStartProvisionalNavigation:)]) {
        [strongSelfDelegate webView:self didStartProvisionalNavigation:strongSelfDelegate];
    }
}

@end

#endif
