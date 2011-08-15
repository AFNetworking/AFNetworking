// NSMutableURLRequest+AFNetworking.m
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

#import "NSMutableURLRequest+AFNetworking.h"
#import "NSData+AFNetworking.h"

@implementation NSMutableURLRequest (AFNetworking)

- (void)setHTTPBodyWithData:(NSData *)data 
                   mimeType:(NSString *)mimeType 
          forParameterNamed:(NSString *)parameterName 
                 parameters:(NSDictionary *)parameters
         useGzipCompression:(BOOL)useGzipCompression
{
	if ([[self HTTPMethod] isEqualToString:@"GET"]) {
		[self setHTTPMethod:@"POST"];
	}
    
    NSString *filename = [[NSString stringWithFormat:@"%d", [[NSDate date] hash]] stringByAppendingPathExtension:[mimeType lastPathComponent]];
	
	static NSString * const boundary = @"----Boundary+0xAbCdEfGbOuNdArY";
	[self setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];
	
	NSMutableData *mutableData = [NSMutableData data];
	[mutableData appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	id key;
	NSEnumerator *enumerator = [parameters keyEnumerator];
	while ((key = [enumerator nextObject])) {
		[mutableData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
		[mutableData appendData:[[NSString stringWithFormat:@"%@", [parameters valueForKey:key]] dataUsingEncoding:NSUTF8StringEncoding]];
		[mutableData appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	}
	
	[mutableData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"", parameterName, filename, nil] dataUsingEncoding:NSUTF8StringEncoding]];
    [mutableData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[mutableData appendData:[[NSString stringWithFormat:@"Content-Type: %@", mimeType] dataUsingEncoding:NSUTF8StringEncoding]];
    [mutableData appendData:[@"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[mutableData appendData:data];
	[mutableData appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
    if (useGzipCompression) {
        NSError *error = nil;
        NSData *compressedData = [mutableData dataByGZipCompressingWithError:&error];
        
        if (!error && compressedData) {
            [self setHTTPBody:compressedData];
            
            // Content-Encoding HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.11
            [self setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
        }
    } else {
        [self setHTTPBody:mutableData];
    }
}

@end
