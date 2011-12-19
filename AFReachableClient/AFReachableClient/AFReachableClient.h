//
//  AFReachableClient.h
//  AFReachableClient
//
//  Created by Kevin Harwood on 12/19/11.
//  Copyright (c) 2011 Alications. All rights reserved.
//

#import "AFNetworking.h"
#import "Reachability.h"

@interface AFReachableClient : AFHTTPClient

@property (nonatomic,readonly) NSURL * reachableHostURL;
@property (nonatomic,readonly) Reachability * reachableHost;

- (id)initWithBaseURL:(NSURL *)url 
     reachableHostURL:(NSURL*)reachableHostURL;

@end
