//
//  AFHTTPResponse.h
//  AFNetworking
//
//  Created by Yaniv Cohen on 09/03/2016.
//  Copyright © 2016 AFNetworking. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AFHTTPResponse : NSObject

@property(nonatomic, strong) id responseObject;
@property(nonatomic, strong) NSURLSessionDataTask *task;
@property(nonatomic, strong) NSError *error;

@end
