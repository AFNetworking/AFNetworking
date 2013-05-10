//
//  AFNetworkingTests.h
//  AFNetworking
//
//  Created by Blake Watters on 5/10/13.
//  Copyright (c) 2013 AFNetworking. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "AFNetworking.h"

#define EXP_SHORTHAND YES
#import "Expecta.h"
#import "OCMock.h"

extern NSString *AFNetworkingTestsBaseURLString;
NSURL *AFNetworkingTestsBaseURL(void);
