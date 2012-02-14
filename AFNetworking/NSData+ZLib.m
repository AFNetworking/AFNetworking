//
//  NSData+ZLib.m
//  Timmas
//
//  Created by Menno Pruijssers on 24-01-12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSData+ZLib.h"
#include <zlib.h>

@implementation NSData (ZLib)
- (NSData *)compress {
    Bytef *bytes = (Bytef *)[self bytes];
    NSUInteger length = [self length];
    bool shouldFinish = YES;
    
    if (length == 0) return nil;
	
	NSUInteger halfLength = length/2;
	
	// We'll take a guess that the compressed data will fit in half the size of the original (ie the max to compress at once is half DATA_CHUNK_SIZE), if not, we'll increase it below
	NSMutableData *outputData = [NSMutableData dataWithLength:length/2]; 
	
	z_stream zStream;
    
    // Setup the inflate stream
	zStream.zalloc = Z_NULL;
	zStream.zfree = Z_NULL;
	zStream.opaque = Z_NULL;
	zStream.avail_in = 0;
	zStream.next_in = 0;
	int status = deflateInit2(&zStream, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY);
	if (status != Z_OK) {
		return nil;
	}

	
    zStream.next_in = bytes;
	zStream.avail_in = (unsigned int)length;
	zStream.avail_out = 0;
    
	NSInteger bytesProcessedAlready = zStream.total_out;
	while (zStream.avail_out == 0) {
		
		if (zStream.total_out-bytesProcessedAlready >= [outputData length]) {
			[outputData increaseLengthBy:halfLength];
		}
		
		zStream.next_out = (Bytef*)[outputData mutableBytes] + zStream.total_out-bytesProcessedAlready;
		zStream.avail_out = (unsigned int)([outputData length] - (zStream.total_out-bytesProcessedAlready));
		status = deflate(&zStream, shouldFinish ? Z_FINISH : Z_NO_FLUSH);
		
		if (status == Z_STREAM_END) {
			break;
		} else if (status != Z_OK) {
			return nil;
		}
	}
    
	// Set real length
	[outputData setLength: zStream.total_out-bytesProcessedAlready];
	
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *fileName = [documentsDirectory stringByAppendingPathComponent:@"tmp.json"];
    [outputData writeToFile:fileName atomically:YES];
    
	return outputData;

}
@end
