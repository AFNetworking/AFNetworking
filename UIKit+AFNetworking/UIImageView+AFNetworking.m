// UIImageView+AFNetworking.m
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

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#import "AFHTTPRequestOperation.h"
#import "AFHTTPClient.h"

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
#import "UIImageView+AFNetworking.h"

@interface AFImageCache : NSCache <AFImageCache>
@end

#pragma mark -

static char kAFImageDataTaskKey;
static NSString * const kAFImageCacheKey_AFNetworking = @"kAFImageCacheKey_AFNetworking";

@interface UIImageView (_AFNetworking)
@property (readwrite, nonatomic, strong, setter = af_setImageDataTask:) NSURLSessionDataTask *af_imageDataTask;
@end

@implementation UIImageView (_AFNetworking)
@dynamic af_imageDataTask;
@end

#pragma mark -

@implementation UIImageView (AFNetworking)

+ (AFHTTPClient *)af_sharedHTTPClient {
    static AFHTTPClient *_af_sharedHTTPClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _af_sharedHTTPClient = [[AFHTTPClient alloc] initWithSessionConfiguration:nil];
        _af_sharedHTTPClient.responseSerializers = @[[AFImageSerializer serializer]];
    });

    return _af_sharedHTTPClient;
}

+ (id<AFImageCache>)af_sharedImageCache {
    
    id<AFImageCache> currentCache = objc_getAssociatedObject([self class], (__bridge const void *)(kAFImageCacheKey_AFNetworking));
    
    if(currentCache) return currentCache;
    
    static AFImageCache *_af_imageCache = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _af_imageCache = [[AFImageCache alloc] init];
        [self setImageCache:_af_imageCache];
    });

    return _af_imageCache;
}

+(void)setImageCache:(id<AFImageCache>)cache {
    objc_setAssociatedObject([self class], (__bridge const void *)(kAFImageCacheKey_AFNetworking), cache, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSURLSessionDataTask *)af_imageDataTask {
    return (NSURLSessionDataTask *)objc_getAssociatedObject(self, &kAFImageDataTaskKey);
}

- (void)af_setImageDataTask:(NSURLSessionDataTask *)dataTask {
    objc_setAssociatedObject(self, &kAFImageDataTaskKey, dataTask, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark -

- (void)setImageWithURL:(NSURL *)url {
    [self setImageWithURL:url placeholderImage:nil];
}

- (void)setImageWithURL:(NSURL *)url
       placeholderImage:(UIImage *)placeholderImage
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];

    [self setImageWithURLRequest:request placeholderImage:placeholderImage success:nil failure:nil];
}

- (void)setImageWithURLRequest:(NSURLRequest *)urlRequest
              placeholderImage:(UIImage *)placeholderImage
                       success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image))success
                       failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure
{
    [self cancelImageDataTask];

    UIImage *cachedImage = [[[self class] af_sharedImageCache] cachedImageForRequest:urlRequest];
    if (cachedImage) {
        if (success) {
            success(nil, nil, cachedImage);
        } else {
            self.image = cachedImage;
        }

        self.af_imageDataTask = nil;
    } else {
        self.image = placeholderImage;

        self.af_imageDataTask = [[[self class] af_sharedHTTPClient] runDataTaskWithRequest:urlRequest success:^(NSHTTPURLResponse *response, id <AFURLResponseSerialization> __unused serializer, id responseObject) {
            if ([[urlRequest URL] isEqual:[self.af_imageDataTask.response URL]]) {
                if (success) {
                    success(urlRequest, response, responseObject);
                } else if (responseObject) {
                    self.image = responseObject;
                }
            }

            [[[self class] af_sharedImageCache] cacheImage:responseObject forRequest:urlRequest];
        } failure:^(NSError *error) {
            if ([[urlRequest URL] isEqual:[self.af_imageDataTask.response URL]]) {
                if (failure) {
                    failure(urlRequest, (NSHTTPURLResponse *)self.af_imageDataTask .response, error);
                }
            }
        }];
    }
}

- (void)cancelImageDataTask {
    [self.af_imageDataTask cancel];
    self.af_imageDataTask = nil;
}




@end

#pragma mark -

static inline NSString * AFImageCacheKeyFromURLRequest(NSURLRequest *request) {
    return [[request URL] absoluteString];
}

@implementation AFImageCache

- (UIImage *)cachedImageForRequest:(NSURLRequest *)request {
    switch ([request cachePolicy]) {
        case NSURLRequestReloadIgnoringCacheData:
        case NSURLRequestReloadIgnoringLocalAndRemoteCacheData:
            return nil;
        default:
            break;
    }

	return [self objectForKey:AFImageCacheKeyFromURLRequest(request)];
}

- (void)cacheImage:(UIImage *)image
        forRequest:(NSURLRequest *)request
{
    if (image && request) {
        [self setObject:image forKey:AFImageCacheKeyFromURLRequest(request)];
    }
}

@end

#endif
