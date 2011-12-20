// YWWeatherAPIClient.m
//
// Copyright (c) 2011 Kevin Harwood
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
