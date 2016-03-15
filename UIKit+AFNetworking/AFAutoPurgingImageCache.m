// AFAutoPurgingImageCache.m
// Copyright (c) 2011–2016 Alamofire Software Foundation ( http://alamofire.org/ )
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

#import <TargetConditionals.h>

#if TARGET_OS_IOS || TARGET_OS_TV 

#import "AFAutoPurgingImageCache.h"

@interface AFCachedImage : NSObject

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, assign) UInt64 totalBytes;
@property (nonatomic, assign) UInt64 currentMemoryUsage;

@end

@implementation AFCachedImage

-(instancetype)initWithImage:(UIImage *)image identifier:(NSString *)identifier {
    if (self = [self init]) {
        self.image = image;
        self.identifier = identifier;

        CGSize imageSize = CGSizeMake(image.size.width * image.scale, image.size.height * image.scale);
        CGFloat bytesPerPixel = 4.0;
        CGFloat bytesPerSize = imageSize.width * imageSize.height;
        self.totalBytes = (UInt64)bytesPerPixel * (UInt64)bytesPerSize;
    }
    return self;
}

- (UIImage*)accessImage {
    return self.image;
}

- (NSString *)description {
    NSString *descriptionString = [NSString stringWithFormat:@"Idenfitier: %@", self.identifier];
    return descriptionString;

}

@end

@interface AFLinkedListNode : NSObject
@property (nonatomic, strong) AFCachedImage *image;
@property (nonatomic, strong) AFLinkedListNode *next;
@property (nonatomic, weak) AFLinkedListNode *prev;
@property (nonatomic, copy) NSString *identifier;

- (instancetype)initWithImage:(AFCachedImage *)image identifier:(NSString *)identifier;
@end

@implementation AFLinkedListNode

- (instancetype)initWithImage:(AFCachedImage *)image identifier:(NSString *)identifier
{
    self = [super init];
    if (self) {
        _image = image;
        _identifier = identifier;
    }
    return self;
}

@end

@interface AFAutoPurgingImageCache ()
@property (nonatomic, strong) NSMutableDictionary <NSString* , AFLinkedListNode*> *cachedImages;
@property (nonatomic, assign) UInt64 currentMemoryUsage;
@property (nonatomic, strong) dispatch_queue_t synchronizationQueue;
@property (nonatomic, strong) AFLinkedListNode *head;
@property (nonatomic, strong) AFLinkedListNode *tail;
@end

@implementation AFAutoPurgingImageCache

- (instancetype)init {
    return [self initWithMemoryCapacity:100 * 1024 * 1024 preferredMemoryCapacity:60 * 1024 * 1024];
}

- (instancetype)initWithMemoryCapacity:(UInt64)memoryCapacity preferredMemoryCapacity:(UInt64)preferredMemoryCapacity {
    if (self = [super init]) {
        self.memoryCapacity = memoryCapacity;
        self.preferredMemoryUsageAfterPurge = preferredMemoryCapacity;
        self.cachedImages = [[NSMutableDictionary alloc] init];

        NSString *queueName = [NSString stringWithFormat:@"com.alamofire.autopurgingimagecache-%@", [[NSUUID UUID] UUIDString]];
        self.synchronizationQueue = dispatch_queue_create([queueName cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_CONCURRENT);

        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(removeAllImages)
         name:UIApplicationDidReceiveMemoryWarningNotification
         object:nil];

    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UInt64)memoryUsage {
    __block UInt64 result = 0;
    dispatch_sync(self.synchronizationQueue, ^{
        result = self.currentMemoryUsage;
    });
    return result;
}

- (BOOL)isExceedingMaxUsageAfterAddingImage:(AFCachedImage *)image
{
    return self.currentMemoryUsage + image.totalBytes > self.memoryCapacity;
}

- (void)removeNode:(AFLinkedListNode *)node
{
    if (node == self.head && node == self.tail) {
        self.head = nil;
        self.tail = nil;
        return;
    }
    if (node == self.head) {
        node.next.prev = nil;
        self.head = node.next;
    } else if (node == self.tail) {
        node.prev.next = nil;
        self.tail = node.prev;
    } else {
        node.next.prev = node.prev;
        node.prev.next = node.next;
    }
}

- (void)addNodeToHead:(AFLinkedListNode *)node
{
    node.prev = nil;
    self.head.prev = node;
    node.next = self.head;
    self.head = node;
}


- (void)addImage:(UIImage *)image withIdentifier:(NSString *)identifier {
    dispatch_barrier_async(self.synchronizationQueue, ^{
        AFCachedImage *cacheImage = [[AFCachedImage alloc] initWithImage:image identifier:identifier];
        AFLinkedListNode *cachedImageNode = self.cachedImages[identifier];
        if (cachedImageNode != nil) {
            AFCachedImage *previouslyCachedImage = cachedImageNode.image;
            cachedImageNode.image = cacheImage;
            [self removeNode:cachedImageNode];
            self.currentMemoryUsage -= previouslyCachedImage.totalBytes;
        } else {
            cachedImageNode = [[AFLinkedListNode alloc] initWithImage:cacheImage identifier:identifier];
            self.cachedImages[identifier] = cachedImageNode;
        }
        [self addNodeToHead:cachedImageNode];
        if (self.tail == nil) {
            self.tail = cachedImageNode;
        }
        self.currentMemoryUsage += cachedImageNode.image.totalBytes;
        if (self.currentMemoryUsage > self.memoryCapacity) {
            while (self.currentMemoryUsage > self.preferredMemoryUsageAfterPurge) {
                AFLinkedListNode *currentTail = self.tail;
                [self removeNode:currentTail];
                [self.cachedImages removeObjectForKey:currentTail.identifier];
                self.currentMemoryUsage -= currentTail.image.totalBytes;
                currentTail = nil;
            }
        }
    });
}

- (BOOL)removeImageWithIdentifier:(NSString *)identifier {
    __block BOOL removed = NO;
    dispatch_barrier_sync(self.synchronizationQueue, ^{
        AFLinkedListNode *cachedImageNode = self.cachedImages[identifier];
        if (cachedImageNode != nil) {
            [self.cachedImages removeObjectForKey:identifier];
            [self removeNode:cachedImageNode];
            self.currentMemoryUsage -= cachedImageNode.image.totalBytes;
            removed = YES;
        }
    });
    return removed;
}

- (BOOL)removeAllImages {
    __block BOOL removed = NO;
    dispatch_barrier_sync(self.synchronizationQueue, ^{
        if (self.cachedImages.count > 0) {
            [self.cachedImages removeAllObjects];
            self.currentMemoryUsage = 0;
            self.head = nil;
            self.tail = nil;
            removed = YES;
        }
    });
    return removed;
}

- (nullable UIImage *)imageWithIdentifier:(NSString *)identifier {
    __block UIImage *image = nil;
    dispatch_sync(self.synchronizationQueue, ^{
        AFLinkedListNode *cachedImageNode = self.cachedImages[identifier];
        image = [cachedImageNode.image accessImage];
        if (cachedImageNode != self.head) {
            [self removeNode:cachedImageNode];
            [self addNodeToHead:cachedImageNode];
        }
    });
    return image;
}

- (void)addImage:(UIImage *)image forRequest:(NSURLRequest *)request withAdditionalIdentifier:(NSString *)identifier {
    [self addImage:image withIdentifier:[self imageCacheKeyFromURLRequest:request withAdditionalIdentifier:identifier]];
}

- (BOOL)removeImageforRequest:(NSURLRequest *)request withAdditionalIdentifier:(NSString *)identifier {
    return [self removeImageWithIdentifier:[self imageCacheKeyFromURLRequest:request withAdditionalIdentifier:identifier]];
}

- (nullable UIImage *)imageforRequest:(NSURLRequest *)request withAdditionalIdentifier:(NSString *)identifier {
    return [self imageWithIdentifier:[self imageCacheKeyFromURLRequest:request withAdditionalIdentifier:identifier]];
}

- (NSString *)imageCacheKeyFromURLRequest:(NSURLRequest *)request withAdditionalIdentifier:(NSString *)additionalIdentifier {
    NSString *key = request.URL.absoluteString;
    if (additionalIdentifier != nil) {
        key = [key stringByAppendingString:additionalIdentifier];
    }
    return key;
}

@end

#endif
