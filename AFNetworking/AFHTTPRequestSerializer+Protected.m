//
//  AFHTTPRequestSerializer+Protected.m
//  AFNetworking
//
//  Created by Diego Chohfi on 3/22/16.
//  Copyright © 2016 AFNetworking. All rights reserved.
//

#import "AFHTTPRequestSerializer+Protected.h"

@implementation AFHTTPRequestSerializer (Protected)

- (void)addUserAgentHeaderField {
    NSString *userAgent = nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
#if TARGET_OS_IOS
    // User-Agent Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.43
    userAgent = [NSString stringWithFormat:@"%@/%@ (%@; iOS %@; Scale/%0.2f)",
                 self.bundleIdentifier,
                 self.bundleVersion,
                 self.deviceModel,
                 self.systemVersion,
                 self.screenScale];
#elif TARGET_OS_WATCH
    // User-Agent Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.43
    userAgent = [NSString stringWithFormat:@"%@/%@ (%@; watchOS %@; Scale/%0.2f)",
                 self.bundleIdentifier,
                 self.bundleVersion,
                 self.deviceModel,
                 self.systemVersion,
                 self.screenScale];
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
    userAgent = [NSString stringWithFormat:@"%@/%@ (Mac OS X %@)",
                 self.bundleIdentifier,
                 self.bundleVersion,
                 self.systemVersion];
#endif
#pragma clang diagnostic pop
    if (userAgent) {
        if (![userAgent canBeConvertedToEncoding:NSASCIIStringEncoding]) {
            NSMutableString *mutableUserAgent = [userAgent mutableCopy];
            if (CFStringTransform((__bridge CFMutableStringRef)(mutableUserAgent), NULL, (__bridge CFStringRef)@"Any-Latin; Latin-ASCII; [:^ASCII:] Remove", false)) {
                userAgent = mutableUserAgent;
            }
        }
        [self setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    }
}

- (NSString *)bundleIdentifier {
    return [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleExecutableKey] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleIdentifierKey];
}

- (NSString *)bundleVersion {
    return [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleVersionKey];
}

- (NSString *)deviceModel {
#if TARGET_OS_IOS
    return [[UIDevice currentDevice] model];
#elif TARGET_OS_WATCH
    return [[WKInterfaceDevice currentDevice] model];
#endif
}

- (NSString *)systemVersion {
#if TARGET_OS_IOS
    return [[UIDevice currentDevice] systemVersion];
#elif TARGET_OS_WATCH
    return [[WKInterfaceDevice currentDevice] systemVersion];
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
    return [[NSProcessInfo processInfo] operatingSystemVersionString];
#endif
}

- (float)screenScale {
#if TARGET_OS_IOS
    return [[UIScreen mainScreen] scale];
#elif TARGET_OS_WATCH
    return [[WKInterfaceDevice currentDevice] screenScale];
#endif
}


@end
