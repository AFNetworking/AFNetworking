//
//  YWWeatherAPIClient.m
//  AFReachableExample
//
//  Created by Kevin Harwood on 12/20/11.
//  Copyright (c) 2011 Mutual Mobile. All rights reserved.
//

#import "YWWeatherAPIClient.h"

NSString * const kYWWeatherAPIClientBaseURLString = @"http://weather.yahooapis.com/";
NSString * const kYWWeatherAPIClientBaseReachableURLString = @"www.yahoo.com";

NSString * const kYWWeatherAPIClientForecastMethod = @"forecastjson";
NSString * const kYWWeatherAPIClientWOEIDParameter = @"w";

@implementation YWWeatherAPIClient

- (void)requestWeatherWithWOEID:(NSInteger)WOEID
                        success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                        failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure{
    
    NSDictionary * parameterDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [NSString stringWithFormat:@"%05d",WOEID],kYWWeatherAPIClientWOEIDParameter, nil];
    
    [self 
     getPath:kYWWeatherAPIClientForecastMethod
     parameters:parameterDictionary
     success:success
     failure:failure];
}


#pragma mark - Singleton Methods
+ (YWWeatherAPIClient *)sharedClient {
    static YWWeatherAPIClient *_sharedClient = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedClient = [[self alloc] initWithBaseURL:[NSURL URLWithString:kYWWeatherAPIClientBaseURLString] 
                                     reachableHostURL:[NSURL URLWithString:kYWWeatherAPIClientBaseReachableURLString]];
    });
    
    return _sharedClient;
}

- (id)initWithBaseURL:(NSURL *)url 
     reachableHostURL:(NSURL *)reachableHostURL {
    self = [super initWithBaseURL:url 
                 reachableHostURL:reachableHostURL];
    
    if (!self) {
        return nil;
    }
    
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
    
    [self setDefaultHeader:@"Accept" value:@"application/json"];
    
    [self.operationQueue setMaxConcurrentOperationCount:1];
    
    return self;
}

@end
