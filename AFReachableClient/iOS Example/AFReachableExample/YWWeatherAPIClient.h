//
//  YWWeatherAPIClient.h
//  AFReachableExample
//
//  Created by Kevin Harwood on 12/20/11.
//  Copyright (c) 2011 Mutual Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFReachableClient.h"

@interface YWWeatherAPIClient : AFReachableClient

+ (id)sharedClient;

- (void)requestWeatherWithWOEID:(NSInteger)WOEID
                        success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                        failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

@end
