//
//  UIImage+AFNetworking.m
//  
//
//  Created by Paulo Ferreira on 08/07/15.
//
//

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)

#import "UIImage+AFNetworking.h"

static NSLock* imageLock = nil;

@implementation UIImage (AFNetworking)

+ (void) initialize
{
    imageLock = [[NSLock alloc] init];
}

+ (UIImage*) safeImageWithData:(NSData*)data {
    UIImage* image = nil;
    [imageLock lock];
    image = [UIImage imageWithData:data];
    [imageLock unlock];
    return image;
}
@end

#endif
