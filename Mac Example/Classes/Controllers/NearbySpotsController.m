// NearbySpotsViewController.m
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

#import "NearbySpotsController.h"

#import "Spot.h"

@interface NearbySpotsController ()
@property (strong) CLLocationManager *locationManager;

- (void)loadSpotsForLocation:(CLLocation *)location;
@end

@implementation NearbySpotsController
@synthesize nearbySpots = _nearbySpots;
@synthesize locationManager = _locationManager;

- (id)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.nearbySpots = [NSArray array];
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.distanceFilter = 80.0;
    
    return self;
}

- (void)awakeFromNib {
    // Load from a fixed location, in case location services are disabled or unavailable
    CLLocation *austin = [[CLLocation alloc] initWithLatitude:30.2669444 longitude:-97.7427778];
    [self loadSpotsForLocation:austin];
    
    [self.locationManager startUpdatingLocation];
}

- (void)loadSpotsForLocation:(CLLocation *)location {
    [Spot spotsWithURLString:@"/spots" near:location parameters:[NSDictionary dictionaryWithObject:@"128" forKey:@"per_page"] block:^(NSArray *records) {
        self.nearbySpots = [records sortedArrayUsingComparator:^ NSComparisonResult(id obj1, id obj2) {
            CLLocationDistance d1 = [[(Spot *)obj1 location] distanceFromLocation:location];
            CLLocationDistance d2 = [[(Spot *)obj2 location] distanceFromLocation:location];
            
            if (d1 < d2) {
                return NSOrderedAscending;
            } else if (d1 > d2) {
                return NSOrderedDescending;
            } else {
                return NSOrderedSame;
            }
        }];      
    }];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    [self loadSpotsForLocation:newLocation];
}

@end
