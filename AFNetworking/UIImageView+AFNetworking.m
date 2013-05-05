// UIImageView+AFNetworking.m
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

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <CommonCrypto/CommonDigest.h>

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
#import "UIImageView+AFNetworking.h"
#import "AFImageFilter.h"

@interface AFImageCache : NSCache
- (UIImage *)cachedImageForRequest:(NSURLRequest *)request;
- (void)cacheImage:(UIImage *)image
        forRequest:(NSURLRequest *)request;
@end

@interface UIImage (_AFNetworking)
@property (strong, readonly) NSString *af_hashValue;
@end

@implementation UIImage (_AFNetworking)

- (NSString *)af_hashValue {
    NSString *hash = objc_getAssociatedObject(self, _cmd);
    
    if (!hash) {
        NSData *data = (__bridge_transfer id)CGDataProviderCopyData(CGImageGetDataProvider(self.CGImage));
        
        hash = [NSString stringWithFormat:@"%d", [data hash]];
        objc_setAssociatedObject(self, _cmd, hash, OBJC_ASSOCIATION_RETAIN);
    }
    
    return hash;
}

@end

#pragma mark -

static char kAFImageRequestOperationObjectKey;
static char kAFImageFiltersKey;

@interface UIImageView (_AFNetworking)
@property (readwrite, nonatomic, strong, setter = af_setImageRequestOperation:) AFImageRequestOperation *af_imageRequestOperation;
@property (nonatomic, strong, readonly) NSMutableArray *af_imageFilters;
@end

@implementation UIImageView (_AFNetworking)
@dynamic af_imageRequestOperation, af_imageFilters;
@end

#pragma mark -

@implementation UIImageView (AFNetworking)

- (NSMutableArray *)af_imageFilters
{
    NSMutableArray *array = objc_getAssociatedObject(self, &kAFImageFiltersKey);
    
    if (!array) {
        array = [NSMutableArray array];
        objc_setAssociatedObject(self, &kAFImageFiltersKey, array, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return array;
}

- (AFHTTPRequestOperation *)af_imageRequestOperation {
    return (AFHTTPRequestOperation *)objc_getAssociatedObject(self, &kAFImageRequestOperationObjectKey);
}

- (void)af_setImageRequestOperation:(AFImageRequestOperation *)imageRequestOperation {
    objc_setAssociatedObject(self, &kAFImageRequestOperationObjectKey, imageRequestOperation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (NSOperationQueue *)af_sharedImageRequestOperationQueue {
    static NSOperationQueue *_af_imageRequestOperationQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _af_imageRequestOperationQueue = [[NSOperationQueue alloc] init];
        [_af_imageRequestOperationQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
    });

    return _af_imageRequestOperationQueue;
}

+ (AFImageCache *)af_sharedImageCache {
    static AFImageCache *_af_imageCache = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _af_imageCache = [[AFImageCache alloc] init];
    });

    return _af_imageCache;
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

    [self setImageWithURLRequest:request placeholderImage:placeholderImage success:NULL failure:NULL];
}

- (void)setImageWithURLRequest:(NSURLRequest *)urlRequest
              placeholderImage:(UIImage *)placeholderImage
                       success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image))success
                       failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure
{
    [self cancelImageRequestOperation];
    
    AFImageRequestOperation *requestOperation = [[AFImageRequestOperation alloc] initWithRequest:urlRequest];
    self.af_imageRequestOperation = requestOperation;
    
    UIImage *cachedImage = [[[self class] af_sharedImageCache] cachedImageForRequest:urlRequest];
    
    if (cachedImage) {
        self.image = placeholderImage;
        
        [self _processImage:cachedImage withFilterChain:[self.af_imageFilters copy] completion:^(UIImage *image) {
            if ([urlRequest isEqual:[self.af_imageRequestOperation request]]) {
                self.image = image;
            }
        }];
    }
    
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, UIImage *responseObject) {
        if ([urlRequest isEqual:[self.af_imageRequestOperation request]]) {
            if (success) {
                success(operation.request, operation.response, responseObject);
                
                if (self.af_imageRequestOperation == operation) {
                    self.af_imageRequestOperation = nil;
                }
            } else if (responseObject) {
                [self _processImage:responseObject withFilterChain:[self.af_imageFilters copy] completion:^(UIImage *image) {
                    if ([urlRequest isEqual:[self.af_imageRequestOperation request]]) {
                        self.image = image;
                    }
                    
                    if (self.af_imageRequestOperation == operation) {
                        self.af_imageRequestOperation = nil;
                    }
                }];
            }
        }
        
        [[[self class] af_sharedImageCache] cacheImage:responseObject forRequest:urlRequest];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if ([urlRequest isEqual:[self.af_imageRequestOperation request]]) {
            if (failure) {
                failure(operation.request, operation.response, error);
            }
            
            if (self.af_imageRequestOperation == operation) {
                self.af_imageRequestOperation = nil;
            }
        }
    }];
    
    [[[self class] af_sharedImageRequestOperationQueue] addOperation:self.af_imageRequestOperation];
}

- (void)cancelImageRequestOperation {
    [self.af_imageRequestOperation cancel];
    self.af_imageRequestOperation = nil;
}

- (void)addImageFilter:(AFImageFilter *)imageFiler {
    NSParameterAssert(imageFiler);
    
    [self.af_imageFilters addObject:imageFiler];
}

#pragma mark - image processing

static NSString *cacheNameForImage(UIImage *image, NSArray *filterChain) {
    NSMutableString *hash = [image.af_hashValue mutableCopy];
    
    for (AFImageFilter *filter in filterChain) {
        [hash appendString:filter.uniqueKey];
    }
    
    return hash;
}

static NSString *pathForImageUniqueKey(NSString *uniqueKey) {
    NSString *basePath = [[NSTemporaryDirectory() stringByAppendingPathComponent:@"AFNetworking"] stringByAppendingPathComponent:@"cachedImages"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:basePath]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:basePath withIntermediateDirectories:YES attributes:nil error:&error];
        NSCAssert(error == nil, @"createDirectoryAtPath failed: %@", error);
    }
    
    return [basePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", uniqueKey]];
}

- (void)_processImage:(UIImage *)image withFilterChain:(NSArray *)filterChain completion:(void(^)(UIImage *image))completion {
    NSParameterAssert(completion);
    
    if (!image || filterChain.count == 0) {
        completion(image);
        return;
    }
    
    static NSCache *imageCache = nil;
    if (!imageCache) {
        imageCache = [[NSCache alloc] init];
    }
    
    NSString *uniqueKey = cacheNameForImage(image, filterChain);
    UIImage *cachedImage = [imageCache objectForKey:uniqueKey];
    
    if (cachedImage) {
        completion(cachedImage);
        return;
    }
    
    static dispatch_queue_t backgroundQueue = NULL;
    if (!backgroundQueue) {
        backgroundQueue = dispatch_queue_create("com.alamofire.networking.image.processing", DISPATCH_QUEUE_CONCURRENT);
    }
    
    NSString *diskPath = pathForImageUniqueKey(uniqueKey);
    if ([[NSFileManager defaultManager] fileExistsAtPath:diskPath]) {
        dispatch_async(backgroundQueue, ^{
            UIImage *image = [[UIImage alloc] initWithContentsOfFile:diskPath];
            [imageCache setObject:image forKey:uniqueKey];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(image);
            });
        });
        return;
    }
    
    dispatch_async(backgroundQueue, ^{
        UIImage *processedImage = image;
        
        for (AFImageFilter *filter in filterChain) {
            @autoreleasepool {
                processedImage = [filter processImage:processedImage];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(processedImage);
        });
        
        [imageCache setObject:processedImage forKey:uniqueKey];
        [UIImagePNGRepresentation(processedImage) writeToFile:diskPath atomically:YES];
    });
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
    
    NSString *cacheKey = AFImageCacheKeyFromURLRequest(request);
    UIImage *cachedImage = [self objectForKey:cacheKey];
    
    if (!cachedImage) {
        NSCachedURLResponse *cachedURLResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:request];
        if (cachedURLResponse && (cachedImage = [[UIImage alloc] initWithData:cachedURLResponse.data])) {
            [self setObject:cachedImage forKey:cacheKey];
        }
    }
    
	return cachedImage;
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
