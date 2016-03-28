//
//  AFHTTPRequestSerializer+Protected.h
//  AFNetworking
//
//  Created by Diego Chohfi on 3/22/16.
//  Copyright © 2016 AFNetworking. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

@interface AFHTTPRequestSerializer (Protected)

- (void)addUserAgentHeaderField;

- (NSString *)bundleIdentifier;
- (NSString *)bundleVersion;
- (NSString *)deviceModel;
- (NSString *)systemVersion;
- (float)screenScale;

@end
