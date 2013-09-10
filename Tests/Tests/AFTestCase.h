//
//  AFTestCase.h
//  AFNetworking Tests
//
//  Created by Kevin Harwood on 9/10/13.
//  Copyright (c) 2013 AFNetworking. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "AFNetworking.h"

#define EXP_SHORTHAND YES
#import "Expecta.h"
#import "OCMock.h"

extern NSString * const AFNetworkingTestsBaseURLString;
@interface AFTestCase : XCTestCase

@end
