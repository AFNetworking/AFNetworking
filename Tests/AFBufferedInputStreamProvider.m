//
//  AFDelayingInputStreamProvider.m
//  AFNetworking Tests
//
//  Created by Dev Floater 53 on 2013-07-02.
//  Copyright (c) 2013 AFNetworking. All rights reserved.
//

#import "AFBufferedInputStreamProvider.h"

@interface AFBufferedInputStreamProvider () <NSStreamDelegate>
@property (nonatomic, strong) NSData *sourceData;

@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, strong) NSOutputStream *outputStream;
@end

@implementation AFBufferedInputStreamProvider

- (id) initWithData:(NSData *)data inputStream:(NSInputStream *__autoreleasing *)outInputStream {
    NSParameterAssert(outInputStream);
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.sourceData = data;
    
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreateBoundPair(NULL, &readStream, &writeStream, 16);
    self.inputStream = CFBridgingRelease(readStream);
    self.outputStream = CFBridgingRelease(writeStream);
    self.outputStream.delegate = self;
    [self.outputStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    [self.outputStream open];
    *outInputStream = self.inputStream;
    
    return self;
}

- (void)dealloc {
    [self cleanup];
}

- (void) cleanup {
    [self.outputStream close];
    self.outputStream.delegate = nil;
    [self.outputStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    self.outputStream = nil;
    
    [self.inputStream close];
    self.inputStream = nil;
}

- (void) writeBytesIfPossible {
    while ([self.outputStream hasSpaceAvailable] && self.bytesWritten < [self.sourceData length]) {
        const uint8_t *bytes = [self.sourceData bytes];
        NSInteger res = [self.outputStream write:bytes+self.bytesWritten maxLength:[self.sourceData length]-self.bytesWritten];
        
        if (res < 0) {
            [self cleanup];
            return;
        }
        else {
            _bytesWritten += res;
        }
    }
    
    if (self.bytesWritten >= [self.sourceData length]) {
        [self cleanup];
    }
}


- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    if (aStream == self.outputStream && (eventCode & NSStreamEventHasSpaceAvailable)) {
        [self writeBytesIfPossible];
    }
    else if (eventCode & NSStreamEventErrorOccurred || eventCode & NSStreamEventEndEncountered) {
        [self cleanup];
    }
}

@end
