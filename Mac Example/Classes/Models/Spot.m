// Spot.m
//
// Copyright (c) 2011 Gowalla (http://gowalla.com/)
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

#import "Spot.h"

#import "AFGowallaAPIClient.h"

@implementation Spot
@synthesize name = _name;
@synthesize imageURLString = _imageURLString;
@synthesize latitude = _latitude;
@synthesize longitude = _longitude;
@dynamic location;

- (id)initWithAttributes:(NSDictionary *)attributes {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.name = [attributes valueForKeyPath:@"name"];
    self.imageURLString = [attributes valueForKeyPath:@"image_url"];
    self.latitude = [attributes valueForKeyPath:@"lat"];
    self.longitude = [attributes valueForKeyPath:@"lng"];
    
    return self;
}

- (CLLocation *)location {
    return [[CLLocation alloc] initWithLatitude:[self.latitude doubleValue] longitude:[self.longitude doubleValue]];
}

+ (void)spotsWithURLString:(NSString *)urlString near:(CLLocation *)location parameters:(NSDictionary *)parameters block:(void (^)(NSArray *records))block {    
    NSDictionary *mutableParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
	if (location) {
		[mutableParameters setValue:[NSString stringWithFormat:@"%1.7f", location.coordinate.latitude] forKey:@"lat"];
		[mutableParameters setValue:[NSString stringWithFormat:@"%1.7f", location.coordinate.longitude] forKey:@"lng"];
	}
    
    [[AFGowallaAPIClient sharedClient] getPath:urlString parameters:mutableParameters success:^(__unused AFHTTPRequestOperation *operation, id JSON) {
        NSMutableArray *mutableRecords = [NSMutableArray array];
        for (NSDictionary *attributes in [JSON valueForKeyPath:@"spots"]) {
            @autoreleasepool {
                Spot *spot = [[Spot alloc] initWithAttributes:attributes];
                [mutableRecords addObject:spot];
            }
        }
        
        if (block) {
            block([NSArray arrayWithArray:mutableRecords]);
        }
    } failure:^(__unused AFHTTPRequestOperation *operation, NSError *error) {
        if (block) {
            block([NSArray array]);
        }
    }];
}

@end
