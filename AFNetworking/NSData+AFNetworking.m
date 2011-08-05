// NSData+AFNetworking.m
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

#import "NSData+AFNetworking.h"
#import <zlib.h>

NSString * const kAFZlibErrorDomain = @"com.alamofire.zlib.error";

static inline NSUInteger NSDataEstimatedCompressedLength(NSData *data) {
    return [data length] / 2;
}

typedef enum {
    GzipDeflate = -1,
    GzipInflate = 1,
} GzipOperation;

@interface NSData (_AFNetworking)
+ (NSData *)dataByTransformingData:(NSData *)data 
                usingGZipOperation:(GzipOperation)operation 
                             error:(NSError **)error;
@end

@implementation NSData (_AFNetworking)

+ (NSData *)dataByTransformingData:(NSData *)data 
                usingGZipOperation:(GzipOperation)operation 
                             error:(NSError **)error
{
    z_stream zStream;
	
	NSUInteger estimatedLength = NSDataEstimatedCompressedLength(data);
	NSMutableData *mutableData = [NSMutableData dataWithLength:estimatedLength];
    
	int status;
	zStream.next_in = (Bytef *)[data bytes];
	zStream.avail_in = (unsigned int)[data length];
	zStream.avail_out = 0;
    
	NSInteger bytesProcessedAlready = zStream.total_out;
	while (zStream.avail_out == 0) {
		if (zStream.total_out - bytesProcessedAlready >= [mutableData length]) {
			[mutableData increaseLengthBy:estimatedLength / 2];
		}
		
		zStream.next_out = [mutableData mutableBytes] + zStream.total_out-bytesProcessedAlready;
		zStream.avail_out = (unsigned int)([mutableData length] - (zStream.total_out-bytesProcessedAlready));
		status = deflate(&zStream, Z_FINISH);
		
		if (status == Z_STREAM_END) {
			break;
		} else if (status != Z_OK) {
            if (error) {
                *error = [NSError errorWithDomain:kAFZlibErrorDomain code:status userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Compression of data failed with code %hi", status] forKey:NSLocalizedDescriptionKey]];
            }
            
			return nil;
		}
	}
    
	[mutableData setLength:zStream.total_out - bytesProcessedAlready];
    
    return mutableData;
}

@end

#pragma mark -

@implementation NSData (AFNetworking)

- (NSData *)dataByGZipCompressingWithError:(NSError **)error {
    return [NSData dataByTransformingData:self usingGZipOperation:GzipDeflate error:error];
}

- (NSData *)dataByGZipDecompressingDataWithError:(NSError **)error {
    return [NSData dataByTransformingData:self usingGZipOperation:GzipInflate error:error];
}

@end
