// AFImageFilter.m
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

#import "AFImageFilter.h"

typedef UIImage *(^AFConcreteBlockImageFilterBlock)(UIImage * image);



@interface AFResizeImageFilter : AFImageFilter
@property (atomic, assign) CGSize size;
- (instancetype)initWithSize:(CGSize)size;
@end

@implementation AFResizeImageFilter

- (instancetype)initWithSize:(CGSize)size {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _size = size;
    
    return self;
}

- (NSString *)uniqueKey
{
    return [NSString stringWithFormat:@"->%@", NSStringFromCGSize(self.size)];
}

- (UIImage *)processImage:(UIImage *)image {
    CGFloat horizontalAspectRatio = self.size.width / image.size.width;
    CGFloat verticalAspectRatio = self.size.height / image.size.height;
    CGFloat ratio = MAX(horizontalAspectRatio, verticalAspectRatio);
    
    CGSize newSize = CGSizeMake(image.size.width * ratio, image.size.height * ratio);
    
    CGRect newRect = CGRectIntegral(CGRectMake(0.0f, 0.0f, newSize.width, newSize.height));
    UIGraphicsBeginImageContext(newRect.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    [image drawInRect:newRect];
    
    UIImage *processedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return processedImage;
}

@end



@interface AFConcreteBlockImageFilter : AFImageFilter
@property (copy) AFConcreteBlockImageFilterBlock block;
@property (copy) NSString *concreteUniqueKey;
- (id)initWithUniqueKey:(NSString *)uniqueKey block:(UIImage *(^)(UIImage * image))block;
@end

@implementation AFConcreteBlockImageFilter

- (id)initWithUniqueKey:(NSString *)uniqueKey block:(AFConcreteBlockImageFilterBlock)block {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    NSParameterAssert(uniqueKey);
    NSParameterAssert(block);
    
    _concreteUniqueKey = [uniqueKey copy];
    _block = block;
    
    return self;
}

- (NSString *)uniqueKey {
    return self.concreteUniqueKey;
}

- (UIImage *)processImage:(UIImage *)image {
    return self.block(image);
}

@end



@implementation AFImageFilter

+ (AFImageFilter *)imageFilterWithTargetSize:(CGSize)size {
    return [[AFResizeImageFilter alloc] initWithSize:size];
}

+ (AFImageFilter *)imageFilterWithUniqueKey:(NSString *)uniqueKey block:(AFConcreteBlockImageFilterBlock)processingBlock {
    return [[AFConcreteBlockImageFilter alloc] initWithUniqueKey:uniqueKey block:processingBlock];
}

- (NSString *)uniqueKey {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (UIImage *)processImage:(UIImage *)image {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

@end
