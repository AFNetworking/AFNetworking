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

static inline NSString * AFImageCacheKey(NSURLRequest *urlRequest, CGSize imageSize, AFImageRequestOptions options) {
    return [[[urlRequest URL] absoluteString] stringByAppendingFormat:@"#%fx%f:%d", imageSize.width, imageSize.height, options];
}

@implementation AFImageCache

+ (id)sharedImageCache {
    static NSCache *_sharedImageCache = nil;
    static dispatch_once_t oncePredicate;

    dispatch_once(&oncePredicate, ^{
        _sharedImageCache = [[self alloc] init];
    });
    
    return _sharedImageCache;
}

- (UIImage *)cachedImageForRequest:(NSURLRequest *)urlRequest
                         imageSize:(CGSize)imageSize
                           options:(AFImageRequestOptions)options
{
    return [self objectForKey:AFImageCacheKey(urlRequest, imageSize, options)];
}

- (void)cacheImage:(UIImage *)image
        forRequest:(NSURLRequest *)urlRequest
         imageSize:(CGSize)imageSize
           options:(AFImageRequestOptions)options
{
    if (!image) {
        return;
    }
    
    [self setObject:image forKey:AFImageCacheKey(urlRequest, imageSize, options)];
}

@end
