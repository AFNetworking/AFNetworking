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
#import "AFHTTPRequestOperation.h"

#import <zlib.h>

NSString * const AFZlibErrorDomain = @"com.alamofire.networking.zlib.error";

static char Base64EncodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

#pragma mark -

@implementation NSData (AFNetworking)

- (NSString *)base64EncodedString {
    NSUInteger length = [self length];
    NSMutableData *mutableData = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    
    uint8_t *input = (uint8_t *)[self bytes];
    uint8_t *output = (uint8_t *)[mutableData mutableBytes];
    
    for (NSUInteger i = 0; i < length; i += 3) {
        NSUInteger value = 0;
        for (NSUInteger j = i; j < (i + 3); j++) {
            value <<= 8;
            
            if (j < length) {
                value |= (0xFF & input[j]); 
            }
        }
        
        NSInteger idx = (i / 3) * 4;
        output[idx + 0] = Base64EncodingTable[(value >> 18) & 0x3F];
        output[idx + 1] = Base64EncodingTable[(value >> 12) & 0x3F];
        output[idx + 2] = (i + 1) < length ? Base64EncodingTable[(value >> 6)  & 0x3F] : '=';
        output[idx + 3] = (i + 2) < length ? Base64EncodingTable[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[[NSString alloc] initWithData:mutableData encoding:NSASCIIStringEncoding] autorelease];
}

- (NSData *)dataByGZipCompressingWithError:(NSError **)error {
    if ([self length] == 0) {
        return self;
    }
	
	z_stream zStream;
    
	zStream.zalloc = Z_NULL;
	zStream.zfree = Z_NULL;
	zStream.opaque = Z_NULL;
	zStream.next_in = (Bytef *)[self bytes];
	zStream.avail_in = [self length];
    zStream.total_out = 0;
    
	if (deflateInit(&zStream, Z_DEFAULT_COMPRESSION) != Z_OK) {
        return nil;
    }
    
    NSUInteger compressionChunkSize = 16384; // 16Kb
	NSMutableData *compressedData = [NSMutableData dataWithLength:compressionChunkSize];
    
	do {
        if (zStream.total_out >= [compressedData length]) {
			[compressedData increaseLengthBy:compressionChunkSize];
		}
        
		zStream.next_out = [compressedData mutableBytes] + zStream.total_out;
		zStream.avail_out = [compressedData length] - zStream.total_out;
		
		deflate(&zStream, Z_FINISH);  
		
	} while (zStream.avail_out == 0);
	
	deflateEnd(&zStream);
	[compressedData setLength:zStream.total_out];
    
	return [NSData dataWithData:compressedData];
}

- (NSData *)dataByGZipDecompressingDataWithError:(NSError **)error {
    z_stream zStream;
	
    zStream.zalloc = Z_NULL;
	zStream.zfree = Z_NULL;
	zStream.next_in = (Bytef *)[self bytes];
	zStream.avail_in = [self length];
	zStream.avail_out = 0;
    zStream.total_out = 0;
    
    NSUInteger estimatedLength = [self length] / 2;
	NSMutableData *decompressedData = [NSMutableData dataWithLength:estimatedLength];
        
    do {
        if (zStream.total_out >= [decompressedData length]) {
			[decompressedData increaseLengthBy:estimatedLength / 2];
		}
        
		zStream.next_out = [decompressedData mutableBytes] + zStream.total_out;
		zStream.avail_out = [decompressedData length] - zStream.total_out;
        
        int status = inflate(&zStream, Z_FINISH);
		
		if (status == Z_STREAM_END) {
			break;
		} else if (status != Z_OK) {
            if (error) {
                *error = [NSError errorWithDomain:AFZlibErrorDomain code:status userInfo:nil];
            }
            
			return nil;
		}  
    } while (zStream.avail_out == 0);
    
	[decompressedData setLength:zStream.total_out];
    
	return [NSData dataWithData:decompressedData];
}

@end
