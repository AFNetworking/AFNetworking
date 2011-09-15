// AFGowallaAPI.m
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

#import "AFGowallaAPIClient.h"

static AFGowallaAPIClient *_sharedClient = nil;

// Replace this with your own API Key, available at http://api.gowalla.com/api/keys/
NSString * const kAFGowallaClientID = @"e7ccb7d3d2414eb2af4663fc91eb2793";

NSString * const kAFGowallaBaseURLString = @"https://api.gowalla.com/";

@implementation AFGowallaAPIClient

+ (id)sharedClient {
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedClient = [[self alloc] init];
    });
    
    return _sharedClient;
}

- (id)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    // X-Gowalla-API-Key HTTP Header; see http://api.gowalla.com/api/docs
	[self setDefaultHeader:@"X-Gowalla-API-Key" value:kAFGowallaClientID];
	
	// X-Gowalla-API-Version HTTP Header; see http://api.gowalla.com/api/docs
	[self setDefaultHeader:@"X-Gowalla-API-Version" value:@"1"];
	
	// X-UDID HTTP Header
	[self setDefaultHeader:@"X-UDID" value:[[UIDevice currentDevice] uniqueIdentifier]];
    
    return self;
}

+ (NSURL *)baseURL {
    return [NSURL URLWithString:kAFGowallaBaseURLString];
}

@end
