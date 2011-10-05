// TTTLocationFormatter.m
//
// Copyright (c) 2011 Mattt Thompson (http://mattt.me)
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

#import "TTTLocationFormatter.h"

static double const kTTTMetersToKilometersCoefficient = 0.001;
static double const kTTTMetersToFeetCoefficient = 3.2808399;
static double const kTTTMetersToYardsCoefficient = 1.0936133;
static double const kTTTMetersToMilesCoefficient = 0.000621371192;

static inline double CLLocationDistanceToKilometers(CLLocationDistance distance) {
    return distance * kTTTMetersToKilometersCoefficient;
}

static inline double CLLocationDistanceToFeet(CLLocationDistance distance) {
    return distance * kTTTMetersToFeetCoefficient;
}

static inline double CLLocationDistanceToYards(CLLocationDistance distance) {
    return distance * kTTTMetersToYardsCoefficient;
}

static inline double CLLocationDistanceToMiles(CLLocationDistance distance) {
    return distance * kTTTMetersToMilesCoefficient;
}

#pragma mark -

static inline double DEG2RAD(double degrees) { 
    return degrees * M_PI / 180; 
}

static inline double RAD2DEG(double radians) { 
    return radians * 180 / M_PI; 
}

static inline CLLocationDegrees CLLocationDegreesBearingBetweenCoordinates(CLLocationCoordinate2D originCoordinate, CLLocationCoordinate2D destinationCoordinate) {
    double lat1 = DEG2RAD(originCoordinate.latitude);
	double lon1 = DEG2RAD(originCoordinate.longitude);
	double lat2 = DEG2RAD(destinationCoordinate.latitude);
	double lon2 = DEG2RAD(destinationCoordinate.longitude);
	
    double dLon = lon2 - lon1;
	double y = sin(dLon) * cos(lat2);
	double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
	double bearing = atan2(y, x) + (2 * M_PI);
	
    // `atan2` works on a range of -π to 0 to π, so add on 2π and perform a modulo check
	if (bearing > (2 * M_PI)) {
		bearing = bearing - (2 * M_PI);
	}
    
	return RAD2DEG(bearing);
}

TTTLocationCardinalDirection TTTLocationCardinalDirectionFromBearing(CLLocationDegrees bearing) {
    if(bearing > 337.5) {
        return TTTNorthDirection;
    } else if(bearing > 292.5) {
        return TTTNorthwestDirection;
    } else if(bearing > 247.5) {
        return TTTWestDirection;
    } else if(bearing > 202.5) {
        return TTTSouthwestDirection;
    } else if(bearing > 157.5) {
        return TTTSouthDirection;
    } else if(bearing > 112.5) {
        return TTTSoutheastDirection;
    } else if(bearing > 67.5) {
        return TTTEastDirection;
    } else if(bearing > 22.5) {
        return TTTNortheastDirection;
    } else {
        return TTTNorthDirection;
    }
}

#pragma mark -

static double const kTTTMetersPerSecondToKilometersPerHourCoefficient = 3.6;
static double const kTTTMetersPerSecondToFeetPerSecondCoefficient = 3.2808399;
static double const kTTTMetersPerSecondToMilesPerHourCoefficient = 2.23693629;

static inline double CLLocationSpeedToKilometersPerHour(CLLocationSpeed speed) {
    return speed * kTTTMetersPerSecondToKilometersPerHourCoefficient;
}

static inline double CLLocationSpeedToFeetPerSecond(CLLocationSpeed speed) {
    return speed * kTTTMetersPerSecondToFeetPerSecondCoefficient;
}

static inline double CLLocationSpeedToMilesPerHour(CLLocationSpeed speed) {
    return speed * kTTTMetersPerSecondToMilesPerHourCoefficient;
}


@interface TTTLocationFormatter ()
@property (readwrite, nonatomic, assign) TTTLocationFormatterCoordinateOrder coordinateOrder;
@property (readwrite, nonatomic, assign) TTTLocationFormatterBearingStyle bearingStyle;
@property (readwrite, nonatomic, assign) TTTLocationUnitSystem unitSystem;
@property (readwrite, nonatomic, retain) NSNumberFormatter *numberFormatter;
@end

@implementation TTTLocationFormatter
@synthesize coordinateOrder = _coordinateOrder;
@synthesize bearingStyle = _bearingStyle;
@synthesize unitSystem = _unitSystem;
@synthesize numberFormatter = _numberFormatter;

- (id)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.coordinateOrder = TTTCoordinateLatLngOrder;
    self.bearingStyle = TTTBearingWordStyle;
    self.unitSystem = TTTMetricSystem;
    
    self.numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
    [self.numberFormatter setLocale:[NSLocale currentLocale]];
    [self.numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [self.numberFormatter setMaximumSignificantDigits:2];
    [self.numberFormatter setUsesSignificantDigits:YES];
    
    return self;
}

- (NSString *)stringFromCoordinate:(CLLocationCoordinate2D)coordinate {
    return [NSString stringWithFormat:NSLocalizedString(@"(%@, %@)", @"Coordinate format"), [self.numberFormatter stringFromNumber:[NSNumber numberWithDouble:coordinate.latitude]], [self.numberFormatter stringFromNumber:[NSNumber numberWithDouble:coordinate.longitude]], nil];
}

- (NSString *)stringFromLocation:(CLLocation *)location {
    return [self stringFromCoordinate:location.coordinate];
}

- (NSString *)stringFromDistance:(CLLocationDistance)distance {
    NSString *distanceString = nil;
    NSString *unitString = nil;
    
    switch (self.unitSystem) {
        case TTTMetricSystem: {
            double kilometerDistance = CLLocationDistanceToKilometers(distance);            
            if (kilometerDistance > 1) {
                distanceString = [self.numberFormatter stringFromNumber:[NSNumber numberWithDouble:kilometerDistance]];
                unitString = NSLocalizedString(@"km", @"Kilometer Unit");
            } else {
                double meterDistance = distance;
                distanceString = [self.numberFormatter stringFromNumber:[NSNumber numberWithDouble:meterDistance]];
                unitString = NSLocalizedString(@"m", @"Meter Unit");
            }
            break; 
        }
            
        case TTTImperialSystem: {
            double feetDistance = CLLocationDistanceToFeet(distance);
            if (feetDistance < 300) {
                distanceString = [self.numberFormatter stringFromNumber:[NSNumber numberWithDouble:feetDistance]];
                unitString = NSLocalizedString(@"ft", @"Feet Unit");
            } else {
                double yardDistance = CLLocationDistanceToYards(distance);
                if (yardDistance < 500) {
                    distanceString = [self.numberFormatter stringFromNumber:[NSNumber numberWithDouble:yardDistance]];
                    unitString = NSLocalizedString(@"yds", @"Yard Unit");
                } else {
                    double milesDistance = CLLocationDistanceToMiles(distance);
                    distanceString = [self.numberFormatter stringFromNumber:[NSNumber numberWithDouble:milesDistance]];
                    unitString = (milesDistance > 1.0 && milesDistance < 1.1) ? NSLocalizedString(@"mile", @"Mile Unit (Singular)") : NSLocalizedString(@"miles", @"Mile Unit (Plural)");
                } 
            }
            break; 
        }
    }
    
    return [NSString stringWithFormat:NSLocalizedString(@"%@ %@", @"#{Distance} #{Unit}"), distanceString, unitString];
}

- (NSString *)stringFromBearing:(CLLocationDegrees)bearing {
    switch (self.bearingStyle) {
        case TTTBearingWordStyle:
            switch (TTTLocationCardinalDirectionFromBearing(bearing)) {
                case TTTNorthDirection:
                    return NSLocalizedString(@"North", @"North Direction");
                case TTTNortheastDirection:
                    return NSLocalizedString(@"Northeast", @"Northeast Direction");
                case TTTEastDirection:
                    return NSLocalizedString(@"East", @"East Direction");
                case TTTSoutheastDirection:
                    return NSLocalizedString(@"Southeast", @"Southeast Direction");
                case TTTSouthDirection:
                    return NSLocalizedString(@"South", @"South Direction");
                case TTTSouthwestDirection:
                    return NSLocalizedString(@"Southwest", @"Southwest Direction");
                case TTTWestDirection:
                    return NSLocalizedString(@"West", @"West Direction");
                case TTTNorthwestDirection:
                    return NSLocalizedString(@"Northwest", @"Northwest Direction");
            }
            break;
        case TTTBearingAbbreviationWordStyle:
            switch (TTTLocationCardinalDirectionFromBearing(bearing)) {
                case TTTNorthDirection:
                    return NSLocalizedString(@"N", @"North Direction Abbreviation");
                case TTTNortheastDirection:
                    return NSLocalizedString(@"NE", @"Northeast Direction Abbreviation");
                case TTTEastDirection:
                    return NSLocalizedString(@"E", @"East Direction Abbreviation");
                case TTTSoutheastDirection:
                    return NSLocalizedString(@"SE", @"Southeast Direction Abbreviation");
                case TTTSouthDirection:
                    return NSLocalizedString(@"S", @"South Direction Abbreviation");
                case TTTSouthwestDirection:
                    return NSLocalizedString(@"SW", @"Southwest Direction Abbreviation");
                case TTTWestDirection:
                    return NSLocalizedString(@"W", @"West Direction Abbreviation");
                case TTTNorthwestDirection:
                    return NSLocalizedString(@"NW", @"Northwest Direction Abbreviation");
            }
            break;
        case TTTBearingNumericStyle:
            return [[self.numberFormatter stringFromNumber:[NSNumber numberWithDouble:bearing]] stringByAppendingString:NSLocalizedString(@"°", @"Degrees Symbol")];
    }
    
    return nil;
}

- (NSString *)stringFromSpeed:(CLLocationSpeed)speed {
    NSString *speedString = nil;
    NSString *unitString = nil;
    
    switch (self.unitSystem) {
        case TTTMetricSystem: {
            double metersPerSecondSpeed = speed;
            double kilometersPerHourSpeed = CLLocationSpeedToKilometersPerHour(speed);
            
            if (kilometersPerHourSpeed > 1) {
                speedString = [self.numberFormatter stringFromNumber:[NSNumber numberWithDouble:kilometersPerHourSpeed]];
                unitString = NSLocalizedString(@"km/h", @"Kilometers Per Hour Unit");
            } else {
                speedString = [self.numberFormatter stringFromNumber:[NSNumber numberWithDouble:metersPerSecondSpeed]];
                unitString = NSLocalizedString(@"m/s", @"Meters Per Second Unit");
            }
            break; 
        }
            
        case TTTImperialSystem: {
            double feetPerSecondSpeed = CLLocationSpeedToFeetPerSecond(speed);
            double milesPerHourSpeed = CLLocationSpeedToMilesPerHour(speed);
            
            if (milesPerHourSpeed > 1) {
                speedString = [self.numberFormatter stringFromNumber:[NSNumber numberWithDouble:milesPerHourSpeed]];
                unitString = NSLocalizedString(@"mph", @"Miles Per Hour Unit");
            } else {
                speedString = [self.numberFormatter stringFromNumber:[NSNumber numberWithDouble:feetPerSecondSpeed]];
                unitString = NSLocalizedString(@"ft/s", @"Feet Per Second Unit");
            }
            break; 
        }
    }
    
    return [NSString stringWithFormat:NSLocalizedString(@"%@ %@", @"#{Speed} #{Unit}"), speedString, unitString];
}

- (NSString *)stringFromDistanceFromLocation:(CLLocation *)originLocation toLocation:(CLLocation *)destinationLocation {    
    return [self stringFromDistance:[destinationLocation distanceFromLocation:originLocation]];
}

- (NSString *)stringFromBearingFromLocation:(CLLocation *)originLocation toLocation:(CLLocation *)destinationLocation {
    return [self stringFromBearing:CLLocationDegreesBearingBetweenCoordinates(originLocation.coordinate, destinationLocation.coordinate)];
}

- (NSString *)stringFromDistanceAndBearingFromLocation:(CLLocation *)originLocation toLocation:(CLLocation *)destinationLocation {
    return [NSString stringWithFormat:NSLocalizedString(@"%@ %@", @"#{Dimensional Quantity} #{Direction}"), [self stringFromDistanceFromLocation:originLocation toLocation:destinationLocation], [self stringFromBearingFromLocation:originLocation toLocation:destinationLocation]];
}

- (NSString *)stringFromVelocityFromLocation:(CLLocation *)originLocation toLocation:(CLLocation *)destinationLocation atSpeed:(CLLocationSpeed)speed {
    return [NSString stringWithFormat:NSLocalizedString(@"%@ %@", @"#{Dimensional Quantity} #{Direction}"), [self stringFromSpeed:speed], [self stringFromBearingFromLocation:originLocation toLocation:destinationLocation]];
}

@end
