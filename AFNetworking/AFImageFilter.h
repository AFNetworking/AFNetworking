// AFImageFilter.h
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



/**
 This class encapsulates image processing done by `UIImageView (AFNetworking)`.
 */
@interface AFImageFilter : NSObject

/**
 Every `AFImageFilter` must return a unique key for the processing being done because it is used to cache the processed image.
 */
@property (strong, readonly) NSString *uniqueKey;

/**
 Processes an image.
 */
- (UIImage *)processImage:(UIImage *)image;

/**
 Creates and returns a new `AFImageFilter` instance which scales an image to a given size in an aspect fill fashion.
 */
+ (AFImageFilter *)imageFilterWithTargetSize:(CGSize)size;

/**
 Creates and returns a new `AFImageFilter` instance which will execute the given `processingBlock`.
 */
+ (AFImageFilter *)imageFilterWithUniqueKey:(NSString *)uniqueKey block:(UIImage *(^)(UIImage *image))processingBlock;

@end
