// AFImageCache.m
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

#import "AFImageCache.h"
#import "AFImageRequestOperation.h"

NSString * const _AFImageCachePath = @"afcache";

@interface UIImage (AFImageCache)

/* Return the number of bytes in bitmap of `image'. */

- (NSUInteger)expectedBitmapSize;

@end

@implementation UIImage (AFImageCache)

- (NSUInteger)expectedBitmapSize {
	return CGImageGetBytesPerRow(self.CGImage) * CGImageGetHeight(self.CGImage);
}

@end

static inline NSString * AFImageCacheKeyFromURLRequest(NSURLRequest *request) {
	return [[request URL] absoluteString];
}

@interface AFImageCache ()
{
	NSCache *_memoryStorage;
	NSURLCache *_diskStorage;
}

@end

@implementation AFImageCache

- (id)init {
	self = [super init];
	if (self != nil) {
		_memoryStorage = [NSCache new];

		_diskStorage = [[NSURLCache alloc] initWithMemoryCapacity:1024
													 diskCapacity:AFImageCacheDiskLimit
														 diskPath:_AFImageCachePath];
	}

	return self;
}

- (UIImage *)cachedImageForRequest:(NSURLRequest *)request {
	switch ([request cachePolicy]) {
		case NSURLRequestReloadIgnoringCacheData:
		case NSURLRequestReloadIgnoringLocalAndRemoteCacheData:
			return nil;
		default:
			break;
	}

	UIImage *cachedImage = [_memoryStorage objectForKey:AFImageCacheKeyFromURLRequest(request)];
	if (cachedImage == nil) {
		cachedImage = [[UIImage alloc] initWithData:[[_diskStorage cachedResponseForRequest:request] data]];

		if (cachedImage != nil) {
			[_memoryStorage setObject:cachedImage
							   forKey:AFImageCacheKeyFromURLRequest(request)
								 cost:[cachedImage expectedBitmapSize]];
		}
	}

	return cachedImage;
}

- (void)cacheImageRequestOperationResponse:(AFImageRequestOperation *)operation {
	NSAssert(operation.responseImage != nil, @"Can't cache nil image for request:%@", operation);

	[_memoryStorage setObject:operation.responseImage
					   forKey:AFImageCacheKeyFromURLRequest(operation.request)
						 cost:[operation.responseImage expectedBitmapSize]];

	NSCachedURLResponse *cachedURLResponse = [[NSCachedURLResponse alloc] initWithResponse:operation.response
																					  data:operation.responseData];
	[_diskStorage storeCachedResponse:cachedURLResponse forRequest:operation.request];
}

@end