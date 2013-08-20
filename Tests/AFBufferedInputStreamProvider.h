//
//  AFDelayingInputStreamProvider.h
//  AFNetworking Tests
//
//  Created by Dev Floater 53 on 2013-07-02.
//  Copyright (c) 2013 AFNetworking. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AFBufferedInputStreamProvider : NSObject

@property (nonatomic, readonly) NSUInteger bytesWritten;

- (id) initWithData:(NSData *)data inputStream:(NSInputStream *__autoreleasing *)outInputStream;

@end
