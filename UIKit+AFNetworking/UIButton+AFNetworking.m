// UIButton+AFNetworking.m
// Copyright (c) 2011–2015 Alamofire Software Foundation (http://alamofire.org/)
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

#import "UIButton+AFNetworking.h"

#import <objc/runtime.h>

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)

#import "AFURLResponseSerialization.h"
#import "AFHTTPRequestOperation.h"

#import "UIImageView+AFNetworking.h"

@interface UIButton (_AFNetworking)
@end

@implementation UIButton (_AFNetworking)

+ (NSOperationQueue *)af_sharedImageRequestOperationQueue {
    static NSOperationQueue *_af_sharedImageRequestOperationQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _af_sharedImageRequestOperationQueue = [[NSOperationQueue alloc] init];
        _af_sharedImageRequestOperationQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
    });

    return _af_sharedImageRequestOperationQueue;
}

#pragma mark -

static char AFImageRequestOperationNormal;
static char AFImageRequestOperationHighlighted;
static char AFImageRequestOperationSelected;
static char AFImageRequestOperationDisabled;

static const char * af_imageRequestOperationKeyForState(UIControlState state) {
    switch (state) {
        case UIControlStateHighlighted:
            return &AFImageRequestOperationHighlighted;
        case UIControlStateSelected:
            return &AFImageRequestOperationSelected;
        case UIControlStateDisabled:
            return &AFImageRequestOperationDisabled;
        case UIControlStateNormal:
        default:
            return &AFImageRequestOperationNormal;
    }
}

- (AFHTTPRequestOperation *)af_imageRequestOperationForState:(UIControlState)state {
    return (AFHTTPRequestOperation *)objc_getAssociatedObject(self, af_imageRequestOperationKeyForState(state));
}

- (void)af_setImageRequestOperation:(AFHTTPRequestOperation *)imageRequestOperation
                           forState:(UIControlState)state
{
    objc_setAssociatedObject(self, af_imageRequestOperationKeyForState(state), imageRequestOperation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark -

static char AFBackgroundImageRequestOperationNormal;
static char AFBackgroundImageRequestOperationHighlighted;
static char AFBackgroundImageRequestOperationSelected;
static char AFBackgroundImageRequestOperationDisabled;

static const char * af_backgroundImageRequestOperationKeyForState(UIControlState state) {
    switch (state) {
        case UIControlStateHighlighted:
            return &AFBackgroundImageRequestOperationHighlighted;
        case UIControlStateSelected:
            return &AFBackgroundImageRequestOperationSelected;
        case UIControlStateDisabled:
            return &AFBackgroundImageRequestOperationDisabled;
        case UIControlStateNormal:
        default:
            return &AFBackgroundImageRequestOperationNormal;
    }
}

- (AFHTTPRequestOperation *)af_backgroundImageRequestOperationForState:(UIControlState)state {
    return (AFHTTPRequestOperation *)objc_getAssociatedObject(self, af_backgroundImageRequestOperationKeyForState(state));
}

- (void)af_setBackgroundImageRequestOperation:(AFHTTPRequestOperation *)imageRequestOperation
                                     forState:(UIControlState)state
{
    objc_setAssociatedObject(self, af_backgroundImageRequestOperationKeyForState(state), imageRequestOperation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

#pragma mark -

@implementation UIButton (AFNetworking)

+ (id <AFImageCache>)sharedImageCache {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
    return objc_getAssociatedObject(self, @selector(sharedImageCache)) ?: [UIImageView sharedImageCache];
#pragma clang diagnostic pop
}

+ (void)setSharedImageCache:(__nullable id <AFImageCache>)imageCache {
    objc_setAssociatedObject(self, @selector(sharedImageCache), imageCache, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark -

- (id <AFURLResponseSerialization>)imageResponseSerializer {
    static id <AFURLResponseSerialization> _af_defaultImageResponseSerializer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _af_defaultImageResponseSerializer = [AFImageResponseSerializer serializer];
    });

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
    return objc_getAssociatedObject(self, @selector(imageResponseSerializer)) ?: _af_defaultImageResponseSerializer;
#pragma clang diagnostic pop
}

- (void)setImageResponseSerializer:(id <AFURLResponseSerialization>)serializer {
    objc_setAssociatedObject(self, @selector(imageResponseSerializer), serializer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark -

- (void)setImageForState:(UIControlState)state
                 withURL:(NSURL *)url
{
    [self setImageForState:state withURL:url placeholderImage:nil];
}

- (void)setImageForState:(UIControlState)state
                 withURL:(NSURL *)url
        placeholderImage:(UIImage *)placeholderImage
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];

    [self setImageForState:state withURLRequest:request placeholderImage:placeholderImage success:nil failure:nil];
}

- (void)setImageForState:(UIControlState)state
          withURLRequest:(NSURLRequest *)urlRequest
        placeholderImage:(UIImage *)placeholderImage
                 success:(void (^)(NSURLRequest *request, NSHTTPURLResponse * __nullable response, UIImage *image))success
                 failure:(void (^)(NSError *error))failure
{
    [self cancelImageRequestOperationForState:state];

    UIImage *cachedImage = [[[self class] sharedImageCache] cachedImageForRequest:urlRequest];
    if (cachedImage) {
        if (success) {
            success(urlRequest, nil, cachedImage);
        } else {
            [self setImage:cachedImage forState:state];
        }

        [self af_setImageRequestOperation:nil forState:state];
    } else {
        if (placeholderImage) {
            [self setImage:placeholderImage forState:state];
        }

        __weak __typeof(self)weakSelf = self;
        AFHTTPRequestOperation *imageRequestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
        imageRequestOperation.responseSerializer = self.imageResponseSerializer;
        [imageRequestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            if ([[urlRequest URL] isEqual:[operation.request URL]]) {
                if (success) {
                    success(operation.request, operation.response, responseObject);
                } else if (responseObject) {
                    [strongSelf setImage:responseObject forState:state];
                }
            }
            [[[strongSelf class] sharedImageCache] cacheImage:responseObject forRequest:urlRequest];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if ([[urlRequest URL] isEqual:[operation.request URL]]) {
                if (failure) {
                    failure(error);
                }
            }
        }];

        [self af_setImageRequestOperation:imageRequestOperation forState:state];
        [[[self class] af_sharedImageRequestOperationQueue] addOperation:imageRequestOperation];
    }
}

#pragma mark -

- (void)setBackgroundImageForState:(UIControlState)state
                           withURL:(NSURL *)url
{
    [self setBackgroundImageForState:state withURL:url placeholderImage:nil];
}

- (void)setBackgroundImageForState:(UIControlState)state
                           withURL:(NSURL *)url
                  placeholderImage:(UIImage *)placeholderImage
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];

    [self setBackgroundImageForState:state withURLRequest:request placeholderImage:placeholderImage success:nil failure:nil];
}

- (void)setBackgroundImageForState:(UIControlState)state
                    withURLRequest:(NSURLRequest *)urlRequest
                  placeholderImage:(UIImage *)placeholderImage
                           success:(void (^)(NSURLRequest *request, NSHTTPURLResponse * __nullable response, UIImage *image))success
                           failure:(void (^)(NSError *error))failure
{
    [self cancelBackgroundImageRequestOperationForState:state];

    UIImage *cachedImage = [[[self class] sharedImageCache] cachedImageForRequest:urlRequest];
    if (cachedImage) {
        if (success) {
            success(urlRequest, nil, cachedImage);
        } else {
            [self setBackgroundImage:cachedImage forState:state];
        }

        [self af_setBackgroundImageRequestOperation:nil forState:state];
    } else {
        if (placeholderImage) {
            [self setBackgroundImage:placeholderImage forState:state];
        }

        __weak __typeof(self)weakSelf = self;
        AFHTTPRequestOperation *backgroundImageRequestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
        backgroundImageRequestOperation.responseSerializer = self.imageResponseSerializer;
        [backgroundImageRequestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            if ([[urlRequest URL] isEqual:[operation.request URL]]) {
                if (success) {
                    success(operation.request, operation.response, responseObject);
                } else if (responseObject) {
                    [strongSelf setBackgroundImage:responseObject forState:state];
                }
            }
            [[[strongSelf class] sharedImageCache] cacheImage:responseObject forRequest:urlRequest];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if ([[urlRequest URL] isEqual:[operation.request URL]]) {
                if (failure) {
                    failure(error);
                }
            }
        }];

        [self af_setBackgroundImageRequestOperation:backgroundImageRequestOperation forState:state];
        [[[self class] af_sharedImageRequestOperationQueue] addOperation:backgroundImageRequestOperation];
    }
}

#pragma mark -

- (void)cancelImageRequestOperationForState:(UIControlState)state {
    [[self af_imageRequestOperationForState:state] cancel];
    [self af_setImageRequestOperation:nil forState:state];
}

- (void)cancelBackgroundImageRequestOperationForState:(UIControlState)state {
    [[self af_backgroundImageRequestOperationForState:state] cancel];
    [self af_setBackgroundImageRequestOperation:nil forState:state];
}

@end

#endif
