// AFSerialization.h
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

#import "AFURLResponseSerialization.h"

extern NSString * const AFNetworkingErrorDomain;
extern NSString * const AFNetworkingOperationFailingURLResponseErrorKey;

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
#import <UIKit/UIKit.h>
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
#import <Cocoa/Cocoa.h>
#endif

@implementation AFHTTPResponseSerializer

+ (instancetype)serializer {
    return [[self alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.stringEncoding = NSUTF8StringEncoding;

    self.acceptableStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
    self.acceptableContentTypes = nil;

    return self;
}

#pragma mark -

- (BOOL)validateResponse:(NSHTTPURLResponse *)response
                    data:(NSData *)data
                   error:(NSError *__autoreleasing *)error
{
    if (response && [response isKindOfClass:[NSHTTPURLResponse class]]) {
        if (self.acceptableStatusCodes && ![self.acceptableStatusCodes containsIndex:(NSUInteger)response.statusCode]) {
            NSDictionary *userInfo = @{
                                       NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedStringFromTable(@"Request failed: %@ (%d)", @"AFNetworking", nil), [NSHTTPURLResponse localizedStringForStatusCode:response.statusCode], response.statusCode],
                                       NSURLErrorFailingURLErrorKey:[response URL],
                                       AFNetworkingOperationFailingURLResponseErrorKey: response
                                       };
            if (error) {
                *error = [[NSError alloc] initWithDomain:AFNetworkingErrorDomain code:NSURLErrorBadServerResponse userInfo:userInfo];
            }

            return NO;
        } else if (self.acceptableContentTypes && ![self.acceptableContentTypes containsObject:[response MIMEType]]) {
            // Don't invalidate content type if there is no content
            if ([data length] > 0) {
                NSDictionary *userInfo = @{
                                           NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedStringFromTable(@"Request failed: unacceptable content-type: %@", @"AFNetworking", nil), [response MIMEType]],
                                           NSURLErrorFailingURLErrorKey:[response URL],
                                           AFNetworkingOperationFailingURLResponseErrorKey: response
                                           };
                if (error) {
                    *error = [[NSError alloc] initWithDomain:AFNetworkingErrorDomain code:NSURLErrorCannotDecodeContentData userInfo:userInfo];
                }

                return NO;
            }
        }
    }

    return YES;
}

#pragma mark - AFURLResponseSerialization

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    [self validateResponse:(NSHTTPURLResponse *)response data:data error:error];

    return data;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    if (!self) {
        return nil;
    }

    self.acceptableStatusCodes = [aDecoder decodeObjectForKey:@"acceptableStatusCodes"];
    self.acceptableContentTypes = [aDecoder decodeObjectForKey:@"acceptableContentTypes"];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.acceptableStatusCodes forKey:@"acceptableStatusCodes"];
    [aCoder encodeObject:self.acceptableContentTypes forKey:@"acceptableContentTypes"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    AFHTTPResponseSerializer *serializer = [[[self class] allocWithZone:zone] init];
    serializer.acceptableStatusCodes = [self.acceptableStatusCodes copyWithZone:zone];
    serializer.acceptableContentTypes = [self.acceptableContentTypes copyWithZone:zone];

    return serializer;
}

@end

#pragma mark -

@implementation AFJSONResponseSerializer

+ (instancetype)serializer {
    return [self serializerWithReadingOptions:0];
}

+ (instancetype)serializerWithReadingOptions:(NSJSONReadingOptions)readingOptions {
    AFJSONResponseSerializer *serializer = [[self alloc] init];
    serializer.readingOptions = readingOptions;

    return serializer;
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", nil];

    return self;
}

#pragma mark - AFURLRequestSerialization

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    if (![self validateResponse:(NSHTTPURLResponse *)response data:data error:error]) {
        if ([(NSError *)(*error) code] == NSURLErrorCannotDecodeContentData) {
            return nil;
        }
    }

    // Workaround for behavior of Rails to return a single space for `head :ok` (a workaround for a bug in Safari), which is not interpreted as valid input by NSJSONSerialization.
    // See https://github.com/rails/rails/issues/1742
    NSStringEncoding stringEncoding = self.stringEncoding;
    if (response.textEncodingName) {
        CFStringEncoding encoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)response.textEncodingName);
        if (encoding != kCFStringEncodingInvalidId) {
            stringEncoding = CFStringConvertEncodingToNSStringEncoding(encoding);
        }
    }
    
    NSString *responseString = [[NSString alloc] initWithData:data encoding:stringEncoding];
    if (responseString && ![responseString isEqualToString:@" "]) {
        // Workaround for a bug in NSJSONSerialization when Unicode character escape codes are used instead of the actual character
        // See http://stackoverflow.com/a/12843465/157142
        data = [responseString dataUsingEncoding:NSUTF8StringEncoding];

        if (data) {
            if ([data length] > 0) {
                return [NSJSONSerialization JSONObjectWithData:data options:self.readingOptions error:error];
            } else {
                return nil;
            }
        } else {
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
            [userInfo setValue:NSLocalizedStringFromTable(@"Data failed decoding as a UTF-8 string", nil, @"AFNetworking") forKey:NSLocalizedDescriptionKey];
            [userInfo setValue:[NSString stringWithFormat:NSLocalizedStringFromTable(@"Could not decode string: %@", nil, @"AFNetworking"), responseString] forKey:NSLocalizedFailureReasonErrorKey];
            if (error) {
                *error = [[NSError alloc] initWithDomain:AFNetworkingErrorDomain code:NSURLErrorCannotDecodeContentData userInfo:userInfo];
            }
        }
    }

    return nil;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (!self) {
        return nil;
    }

    self.readingOptions = [aDecoder decodeIntegerForKey:@"readingOptions"];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];

    [aCoder encodeInteger:self.readingOptions forKey:@"readingOptions"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    AFJSONResponseSerializer *serializer = [[[self class] allocWithZone:zone] init];
    serializer.readingOptions = self.readingOptions;

    return serializer;
}

@end

#pragma mark -

@implementation AFXMLParserResponseSerializer

+ (instancetype)serializer {
    AFXMLParserResponseSerializer *serializer = [[self alloc] init];

    return serializer;
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.acceptableContentTypes = [[NSSet alloc] initWithObjects:@"application/xml", @"text/xml", nil];

    return self;
}

#pragma mark - AFURLResponseSerialization

- (id)responseObjectForResponse:(NSHTTPURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    if (![self validateResponse:(NSHTTPURLResponse *)response data:data error:error]) {
        if ([(NSError *)(*error) code] == NSURLErrorCannotDecodeContentData) {
            return nil;
        }
    }

    return [[NSXMLParser alloc] initWithData:data];
}

@end

#pragma mark -

#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED

@implementation AFXMLDocumentResponseSerializer

+ (instancetype)serializer {
    return [self serializerWithXMLDocumentOptions:0];
}

+ (instancetype)serializerWithXMLDocumentOptions:(NSUInteger)mask {
    AFXMLDocumentResponseSerializer *serializer = [[self alloc] init];
    serializer.options = mask;

    return serializer;
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.acceptableContentTypes = [[NSSet alloc] initWithObjects:@"application/xml", @"text/xml", nil];

    return self;
}

#pragma mark - AFURLResponseSerialization

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    if (![self validateResponse:(NSHTTPURLResponse *)response data:data error:error]) {
        if ([(NSError *)(*error) code] == NSURLErrorCannotDecodeContentData) {
            return nil;
        }
    }

    return [[NSXMLDocument alloc] initWithData:data options:self.options error:error];
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (!self) {
        return nil;
    }

    self.options = [aDecoder decodeIntegerForKey:@"options"];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];

    [aCoder encodeInteger:self.options forKey:@"options"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    AFXMLDocumentResponseSerializer *serializer = [[[self class] allocWithZone:zone] init];
    serializer.options = self.options;

    return serializer;
}

@end

#endif

#pragma mark -

@implementation AFPropertyListResponseSerializer

+ (instancetype)serializer {
    return [self serializerWithFormat:NSPropertyListXMLFormat_v1_0 readOptions:0];
}

+ (instancetype)serializerWithFormat:(NSPropertyListFormat)format
                         readOptions:(NSPropertyListReadOptions)readOptions
{
    AFPropertyListResponseSerializer *serializer = [[self alloc] init];
    serializer.format = format;
    serializer.readOptions = readOptions;

    return serializer;
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.acceptableContentTypes = [[NSSet alloc] initWithObjects:@"application/x-plist", nil];

    return self;
}

+ (NSSet *)acceptablePathExtensions {
    static NSSet * _acceptablePathExtension = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _acceptablePathExtension = [[NSSet alloc] initWithObjects:@"plist", nil];
    });

    return _acceptablePathExtension;
}

#pragma mark - AFURLResponseSerialization

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    if (![self validateResponse:(NSHTTPURLResponse *)response data:data error:error]) {
        if ([(NSError *)(*error) code] == NSURLErrorCannotDecodeContentData) {
            return nil;
        }
    }

    return [NSPropertyListSerialization propertyListWithData:data options:self.readOptions format:NULL error:error];
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (!self) {
        return nil;
    }

    self.format = (NSPropertyListFormat)[aDecoder decodeIntegerForKey:@"format"];
    self.readOptions = [aDecoder decodeIntegerForKey:@"readOptions"];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];

    [aCoder encodeInteger:self.format forKey:@"format"];
    [aCoder encodeInteger:(NSInteger)self.readOptions forKey:@"readOptions"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    AFPropertyListResponseSerializer *serializer = [[[self class] allocWithZone:zone] init];
    serializer.format = self.format;
    serializer.readOptions = self.readOptions;

    return serializer;
}

@end

#pragma mark -

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
#import <CoreGraphics/CoreGraphics.h>

static UIImage * AFImageWithDataAtScale(NSData *data, CGFloat scale) {
    UIImage *image = [[UIImage alloc] initWithData:data];

    return [[UIImage alloc] initWithCGImage:[image CGImage] scale:scale orientation:image.imageOrientation];
}

static UIImage * AFInflatedImageFromResponseWithDataAtScale(NSHTTPURLResponse *response, NSData *data, CGFloat scale) {
    if (!data || [data length] == 0) {
        return nil;
    }

    CGImageRef imageRef = nil;
    CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);

    if ([response.MIMEType isEqualToString:@"image/png"]) {
        imageRef = CGImageCreateWithPNGDataProvider(dataProvider,  NULL, true, kCGRenderingIntentDefault);
    } else if ([response.MIMEType isEqualToString:@"image/jpeg"]) {
        imageRef = CGImageCreateWithJPEGDataProvider(dataProvider, NULL, true, kCGRenderingIntentDefault);
    }

    if (!imageRef) {
        UIImage *image = AFImageWithDataAtScale(data, scale);
        if (image.images) {
            CGDataProviderRelease(dataProvider);

            return image;
        }

        imageRef = CGImageCreateCopy([image CGImage]);
    }

    CGDataProviderRelease(dataProvider);

    if (!imageRef) {
        return nil;
    }

    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);

    if (width * height > 1024 * 1024) {
        CGImageRelease(imageRef);

        return AFImageWithDataAtScale(data, scale);
    }

    size_t bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
    size_t bytesPerRow = 0; // CGImageGetBytesPerRow() calculates incorrectly in iOS 5.0, so defer to CGBitmapContextCreate()
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);

    if (CGColorSpaceGetNumberOfComponents(colorSpace) == 3) {
        uint32_t alpha = (bitmapInfo & kCGBitmapAlphaInfoMask);
        if (alpha == kCGImageAlphaNone) {
            bitmapInfo &= ~kCGBitmapAlphaInfoMask;
            bitmapInfo |= kCGImageAlphaNoneSkipFirst;
        } else if (!(alpha == kCGImageAlphaNoneSkipFirst || alpha == kCGImageAlphaNoneSkipLast)) {
            bitmapInfo &= ~kCGBitmapAlphaInfoMask;
            bitmapInfo |= kCGImageAlphaPremultipliedFirst;
        }
    }

    CGContextRef context = CGBitmapContextCreate(NULL, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo);

    CGColorSpaceRelease(colorSpace);

    if (!context) {
        CGImageRelease(imageRef);

        return AFImageWithDataAtScale(data, scale);
    }

    CGRect rect = CGRectMake(0.0f, 0.0f, width, height);
    CGContextDrawImage(context, rect, imageRef);
    CGImageRef inflatedImageRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);

    UIImage *inflatedImage = [[UIImage alloc] initWithCGImage:inflatedImageRef scale:scale orientation:UIImageOrientationUp];
    CGImageRelease(inflatedImageRef);
    CGImageRelease(imageRef);

    return inflatedImage;
}
#endif


@implementation AFImageResponseSerializer

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.acceptableContentTypes = [[NSSet alloc] initWithObjects:@"image/tiff", @"image/jpeg", @"image/gif", @"image/png", @"image/ico", @"image/x-icon", @"image/bmp", @"image/x-bmp", @"image/x-xbitmap", @"image/x-win-bitmap", nil];

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
    self.imageScale = [[UIScreen mainScreen] scale];
    self.automaticallyInflatesResponseImage = YES;
#endif

    return self;
}

+ (NSSet *)acceptablePathExtensions {
    static NSSet * _acceptablePathExtension = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _acceptablePathExtension = [[NSSet alloc] initWithObjects:@"tif", @"tiff", @"jpg", @"jpeg", @"gif", @"png", @"ico", @"bmp", @"cur", nil];
    });

    return _acceptablePathExtension;
}

#pragma mark - AFURLResponseSerializer

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    if (![self validateResponse:(NSHTTPURLResponse *)response data:data error:error]) {
        if ([(NSError *)(*error) code] == NSURLErrorCannotDecodeContentData) {
            return nil;
        }
    }

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
    if (self.automaticallyInflatesResponseImage) {
        return AFInflatedImageFromResponseWithDataAtScale((NSHTTPURLResponse *)response, data, self.imageScale);
    } else {
        return AFImageWithDataAtScale(data, self.imageScale);
    }
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
    // Ensure that the image is set to it's correct pixel width and height
    NSBitmapImageRep *bitimage = [[NSBitmapImageRep alloc] initWithData:data];
    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize([bitimage pixelsWide], [bitimage pixelsHigh])];
    [image addRepresentation:bitimage];

    return image;
#endif

    return nil;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (!self) {
        return nil;
    }

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
    self.imageScale = [aDecoder decodeFloatForKey:@"imageScale"];
    self.automaticallyInflatesResponseImage = [aDecoder decodeBoolForKey:@"automaticallyInflatesResponseImage"];
#endif

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
    [aCoder encodeFloat:self.imageScale forKey:@"imageScale"];
    [aCoder encodeBool:self.automaticallyInflatesResponseImage forKey:@"automaticallyInflatesResponseImage"];
#endif
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    AFImageResponseSerializer *serializer = [[[self class] allocWithZone:zone] init];

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
    serializer.imageScale = self.imageScale;
    serializer.automaticallyInflatesResponseImage = self.automaticallyInflatesResponseImage;
#endif

    return serializer;
}

@end

#pragma mark -

@interface AFCompoundResponseSerializer ()
@property (readwrite, nonatomic, strong) NSArray *responseSerializers;
@end

@implementation AFCompoundResponseSerializer

+ (instancetype)compoundSerializerWithResponseSerializers:(NSArray *)responseSerializers {
    AFCompoundResponseSerializer *serializer = [[self alloc] init];
    serializer.responseSerializers = responseSerializers;

    return serializer;
}

#pragma mark - AFURLResponseSerialization

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    for (id <AFURLResponseSerialization> serializer in self.responseSerializers) {
        if (![serializer isKindOfClass:[AFHTTPResponseSerializer class]]) {
            continue;
        }

        NSError *serializerError = nil;
        id responseObject = [serializer responseObjectForResponse:response data:data error:&serializerError];
        if (responseObject) {
            *error = serializerError;
            return responseObject;
        }
    }
    
    return [super responseObjectForResponse:response data:data error:error];
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (!self) {
        return nil;
    }

    self.responseSerializers = [aDecoder decodeObjectForKey:@"responseSerializers"];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:self.responseSerializers forKey:@"responseSerializers"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    AFCompoundResponseSerializer *serializer = [[[self class] allocWithZone:zone] init];
    serializer.responseSerializers = self.responseSerializers;

    return serializer;
}

@end
