// TTTLocationFormatter.h
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

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

typedef enum {
    TTTNorthDirection,
    TTTNortheastDirection,
    TTTEastDirection,
    TTTSoutheastDirection,
    TTTSouthDirection,
    TTTSouthwestDirection,
    TTTWestDirection,
    TTTNorthwestDirection,
} TTTLocationCardinalDirection;

extern TTTLocationCardinalDirection TTTLocationCardinalDirectionFromBearing(CLLocationDegrees bearing);

typedef enum {
    TTTCoordinateLatLngOrder = 0,
    TTTCoordinateLngLatOrder,
} TTTLocationFormatterCoordinateOrder;

typedef enum {
    TTTBearingWordStyle = 0,
    TTTBearingAbbreviationWordStyle,
    TTTBearingNumericStyle,
} TTTLocationFormatterBearingStyle;

typedef enum {
    TTTMetricSystem = 0,
    TTTImperialSystem,
} TTTLocationUnitSystem;

@interface TTTLocationFormatter : NSFormatter {
    TTTLocationFormatterCoordinateOrder _coordinateOrder;
    TTTLocationFormatterBearingStyle _bearingStyle;
    TTTLocationUnitSystem _unitSystem;
    NSNumberFormatter *_numberFormatter;
}

@property (readonly, nonatomic, retain) NSNumberFormatter *numberFormatter;

- (NSString *)stringFromCoordinate:(CLLocationCoordinate2D)coordinate;
- (NSString *)stringFromLocation:(CLLocation *)location;
- (NSString *)stringFromDistance:(CLLocationDistance)distance;
- (NSString *)stringFromBearing:(CLLocationDegrees)bearing;
- (NSString *)stringFromSpeed:(CLLocationSpeed)speed;
- (NSString *)stringFromDistanceFromLocation:(CLLocation *)originLocation toLocation:(CLLocation *)destinationLocation;
- (NSString *)stringFromBearingFromLocation:(CLLocation *)originLocation toLocation:(CLLocation *)destinationLocation;
- (NSString *)stringFromDistanceAndBearingFromLocation:(CLLocation *)originLocation toLocation:(CLLocation *)destinationLocation;
- (NSString *)stringFromVelocityFromLocation:(CLLocation *)originLocation toLocation:(CLLocation *)destinationLocation atSpeed:(CLLocationSpeed)speed;

- (TTTLocationFormatterCoordinateOrder)coordinateOrder; 
- (void)setCoordinateOrder:(TTTLocationFormatterCoordinateOrder)coordinateOrder;

- (TTTLocationFormatterBearingStyle)bearingStyle;
- (void)setBearingStyle:(TTTLocationFormatterBearingStyle)bearingStyle;

- (TTTLocationUnitSystem)unitSystem;
- (void)setUnitSystem:(TTTLocationUnitSystem)unitSystem;

@end
