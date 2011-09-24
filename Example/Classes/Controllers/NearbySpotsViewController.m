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

#import "NearbySpotsViewController.h"

#import "Spot.h"

#import "SpotTableViewCell.h"

#import "TTTLocationFormatter.h"
#import "AFImageCache.h"
#import "UIImageView+AFNetworking.h"

@interface NearbySpotsViewController ()
@property (readwrite, nonatomic, retain) NSArray *nearbySpots;
@property (readwrite, nonatomic, retain) CLLocationManager *locationManager;
@property (readwrite, nonatomic, retain) UIActivityIndicatorView *activityIndicatorView;

- (void)loadSpotsForLocation:(CLLocation *)location;
- (void)refresh:(id)sender;
@end

@implementation NearbySpotsViewController
@synthesize nearbySpots = _spots;
@synthesize locationManager = _locationManager;
@synthesize activityIndicatorView = _activityIndicatorView;

- (id)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.nearbySpots = [NSArray array];
    
    self.locationManager = [[[CLLocationManager alloc] init] autorelease];
    self.locationManager.delegate = self;
    self.locationManager.distanceFilter = 80.0;
    
    return self;
}

- (void)dealloc {
    [_spots release];
    [_locationManager release];
    [_activityIndicatorView release];
    [super dealloc];
}

- (void)loadSpotsForLocation:(CLLocation *)location {
    [self.activityIndicatorView startAnimating];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
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
        
        [self.tableView reloadData];
        
        [self.activityIndicatorView stopAnimating];
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"AFNetworking", nil);
    
    self.activityIndicatorView = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
    self.activityIndicatorView.hidesWhenStopped = YES;
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:self.activityIndicatorView] autorelease];
    
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh:)] autorelease];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    [self.navigationController.navigationBar setTintColor:[UIColor darkGrayColor]];
    
    self.tableView.rowHeight = 70.0f;
    
    [self.locationManager startUpdatingLocation];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    [self.locationManager stopUpdatingLocation];
}

#pragma mark - Actions

- (void)refresh:(id)sender {
    self.nearbySpots = [NSArray array];
    [self.tableView reloadData];
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    [[AFImageCache sharedImageCache] removeAllObjects];
    
    if (self.locationManager.location) {
        [self loadSpotsForLocation:self.locationManager.location];
    }
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    [self loadSpotsForLocation:newLocation];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.nearbySpots count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    SpotTableViewCell *cell = (SpotTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[SpotTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    Spot *spot = [self.nearbySpots objectAtIndex:indexPath.row];
    
    static TTTLocationFormatter *_locationFormatter = nil;
    if (!_locationFormatter) {
        _locationFormatter = [[TTTLocationFormatter alloc] init];
        if (![[[NSLocale currentLocale] objectForKey:NSLocaleUsesMetricSystem] boolValue]) {
            [_locationFormatter setUnitSystem:TTTImperialSystem]; 
        }
    }

    if (self.locationManager.location) {
        cell.detailTextLabel.text = [_locationFormatter stringFromDistanceAndBearingFromLocation:self.locationManager.location toLocation:spot.location];
    }
    
    cell.spot = spot;
    
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([self tableView:tableView numberOfRowsInSection:section] > 0) {
        return NSLocalizedString(@"Nearby Spots", nil);
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
