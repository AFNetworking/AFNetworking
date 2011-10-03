// NSString+AFNetworking.m
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

#import "NSString+AFNetworking.h"

@implementation NSString (AFNetworking)

#ifndef AFNETWORKING_NO_DEPRECATED
- (NSString *)urlEncodedString {
#ifndef NDEBUG
    NSLog(@"Use of deprecated category method: %s", __PRETTY_FUNCTION__);
#endif
    return [self afUrlEncodedString];
}

- (NSString *)urlEncodedStringWithEncoding:(NSStringEncoding)encoding {
#ifndef NDEBUG
    NSLog(@"Use of deprecated category method: %s", __PRETTY_FUNCTION__);
#endif
    return [self afUrlEncodedStringWithEncoding:encoding];
}
#endif

- (NSString*)afUrlEncodedString { 
	return [self afUrlEncodedStringWithEncoding:NSUTF8StringEncoding];
}

// See http://github.com/pokeb/asi-http-request/raw/master/Classes/ASIFormDataRequest.m
- (NSString *)afUrlEncodedStringWithEncoding:(NSStringEncoding)encoding { 
	NSString *urlEncodedString = [(NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)self, NULL, (CFStringRef)@":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`", CFStringConvertNSStringEncodingToEncoding(encoding)) autorelease];
	
    return urlEncodedString ? urlEncodedString : @"";
}

@end
