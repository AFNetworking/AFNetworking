//
//  AFDataItemIdentifier.m
//  AFNetworking iOS
//
//  Created by jufan wang on 2020/3/3.
//  Copyright © 2020 AFNetworking. All rights reserved.
//

#import "AFDataItemIdentifier.h"


@implementation AFDataItemIdentifier

@synthesize dataItemVersion = _dataItemVersion;
@synthesize dataItemID = _dataItemID;

- (void)encodeWithCoder:(NSCoder *)coder {
    if (self.dataItemID) {
        [coder encodeObject:self.dataItemID forKey:@"dataItemID"];
    }
    if (self.dataItemVersion) {
        [coder encodeObject:self.dataItemVersion forKey:@"dataItemVersion"];
    }
}

- (BOOL)updatedCompareTo:(id<AFDataItemIdentifier>)dataItemIdentifier {
    return [dataItemIdentifier.dataItemVersion compare:self.dataItemVersion] == NSOrderedAscending;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super init]) {
        _dataItemID = [coder decodeObjectForKey:@"dataItemID"];
        _dataItemVersion = [coder decodeObjectForKey:@"dataItemVersion"];
    }
    return self;
}

@end
