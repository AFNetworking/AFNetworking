// AFHTTPRequestOperation.m
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

#import "AFHTTPImageLoader.h"

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)

#import "AFHTTPRequestOperation.h"

@interface AFImageCache : NSCache <AFImageCache>
@end

@interface AFHTTPImageLoader ()
@property (readwrite, nonatomic, strong, setter = af_setImageRequestOperation:) AFHTTPRequestOperation *af_imageRequestOperation;
@end

@implementation AFHTTPImageLoader

#pragma mark - Shared Objects

+ (id <AFImageCache>)sharedImageCache {
    static id <AFImageCache> af_sharedImageCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        af_sharedImageCache = [[AFImageCache alloc] init];
    });
	
    return af_sharedImageCache;
}

+ (NSOperationQueue *)af_sharedImageRequestOperationQueue {
    static NSOperationQueue *_af_sharedImageRequestOperationQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _af_sharedImageRequestOperationQueue = [[NSOperationQueue alloc] init];
        _af_sharedImageRequestOperationQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
    });
	
    return _af_sharedImageRequestOperationQueue;
}

#pragma mark - Getters & setters

- (id <AFImageCache>)imageCache
{
	if (!_imageCache)
	{
		_imageCache = [[self class] sharedImageCache];
	}
	
	return _imageCache;
}

- (AFImageResponseSerializer <AFURLResponseSerialization> *)imageResponseSerializer
{
	if (!_imageResponseSerializer)
	{
		_imageResponseSerializer = [[AFImageResponseSerializer alloc] init];
	}
	
	return _imageResponseSerializer;
}

#pragma mark - Requesting images

- (UIImage*)imageWithURL:(NSURL *)url
				 success:(AFHTTPImageLoaderSuccessBlock)success
				 failure:(AFHTTPImageLoaderFailureBlock)failure
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
	
	return [self imageWithURLRequest:request
							 success:success
							 failure:failure];
}

- (UIImage*)imageWithURLRequest:(NSURLRequest *)urlRequest
						success:(AFHTTPImageLoaderSuccessBlock)success
						failure:(AFHTTPImageLoaderFailureBlock)failure
{
	NSParameterAssert(urlRequest);
	
    [self cancelImageRequestOperation];
	
    UIImage* cachedImage = [self.imageCache cachedImageForRequest:urlRequest];
	
	if (!cachedImage) {
		BOOL hasAtLeastOneCompletionBlock = (success || failure);
		
		if (hasAtLeastOneCompletionBlock)
		{
			[self downloadImageWithURLRequest:urlRequest
									  success:success
									  failure:failure];
		}
    }
	
	return cachedImage;
}

/**
 Downloads the image specified by the URL request.  This method does not check against the local cache.
 
 @param	urlRequest		The URL request that identifies the image to download.
 @param	success			The block to execute on success.  Can be nil.
 @param	failure			The block to execute on failure.  Can be nil.
 */
- (void)downloadImageWithURLRequest:(NSURLRequest*)urlRequest
							success:(AFHTTPImageLoaderSuccessBlock)success
							failure:(AFHTTPImageLoaderFailureBlock)failure
{
	NSCAssert([urlRequest isKindOfClass:[NSURLRequest class]], @"Expected a proper request object.");
	
	__weak __typeof(self)weakSelf = self;
	self.af_imageRequestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
	self.af_imageRequestOperation.responseSerializer = self.imageResponseSerializer;
	[self.af_imageRequestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
		__strong __typeof(weakSelf)strongSelf = weakSelf;
		if ([[urlRequest URL] isEqual:[operation.request URL]]) {
			if (success) {
				success(urlRequest, operation.response, responseObject);
			}
		}
		
		[strongSelf.imageCache cacheImage:responseObject forRequest:urlRequest];
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		if ([[urlRequest URL] isEqual:[operation.request URL]]) {
			if (failure) {
				failure(urlRequest, operation.response, error);
			}
		}
	}];
	
	[[[self class] af_sharedImageRequestOperationQueue] addOperation:self.af_imageRequestOperation];
}

#pragma mark - Request Operation handling

- (void)cancelImageRequestOperation {
    [self.af_imageRequestOperation cancel];
    self.af_imageRequestOperation = nil;
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
