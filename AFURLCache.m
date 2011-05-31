// AFURLCache.m
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

#import <CommonCrypto/CommonDigest.h>
#import "AFURLCache.h"

static const NSTimeInterval kAFURLCacheMaintenanceTimeInterval = 30.0;

NSString * AFURLCacheKeyForNSURLRequest(NSURLRequest *request) {
    const char *str = [[[request URL] absoluteString] UTF8String];
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, strlen(str), r);
    return [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
}

@interface AFURLCache () 
@property (nonatomic, retain) NSCountedSet *cachedRequests;
@property (nonatomic, retain) NSMutableDictionary *keyedCachedResponsesByRequest;

@property (nonatomic, retain) NSOperationQueue *periodicMaintenanceOperationQueue;
@property (nonatomic, retain) NSOperation *periodicMaintenanceOperation;
@property (nonatomic, retain) NSTimer *periodicMaintenanceTimer;
@end

@implementation AFURLCache
@synthesize cachedRequests = _cachedRequests;
@synthesize keyedCachedResponsesByRequest = _keyedCachedResponsesByRequest;
@synthesize periodicMaintenanceOperationQueue = _periodicMaintenanceOperationQueue;
@synthesize periodicMaintenanceOperation = _periodicMaintenanceOperation;
@synthesize periodicMaintenanceTimer = _periodicMaintenanceTimer;

+ (NSString *)defaultCachePath {
    return nil;
}

- (id)initWithMemoryCapacity:(NSUInteger)memoryCapacity diskCapacity:(NSUInteger)diskCapacity diskPath:(NSString *)path {
	self = [super initWithMemoryCapacity:memoryCapacity diskCapacity:diskCapacity diskPath:path];
	if (!self) {
		return nil;
	}
	
	self.cachedRequests = [NSCountedSet setWithCapacity:200];
	self.keyedCachedResponsesByRequest = [NSMutableDictionary dictionaryWithCapacity:200];
	
	self.periodicMaintenanceOperationQueue = [[[NSOperationQueue alloc] init] autorelease];
	[self.periodicMaintenanceOperationQueue setMaxConcurrentOperationCount:1];
	self.periodicMaintenanceTimer = [[NSTimer scheduledTimerWithTimeInterval:kAFURLCacheMaintenanceTimeInterval target:self selector:@selector(periodicMaintenance) userInfo:nil repeats:YES] retain];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sweepMemoryCache) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
	
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[_cachedRequests release];
	[_keyedCachedResponsesByRequest release];
	
	[_periodicMaintenanceOperationQueue cancelAllOperations];
	[_periodicMaintenanceOperationQueue release];
	[_periodicMaintenanceOperation release];
	
    [_periodicMaintenanceTimer invalidate];
	_periodicMaintenanceTimer = nil;
	[super dealloc];
}

#pragma mark - NSURLCache

- (NSCachedURLResponse *)cachedResponseForRequest:(NSURLRequest *)request {
    NSString *cacheKey = AFURLCacheKeyForNSURLRequest(request);
	NSCachedURLResponse *cachedResponse = [self.keyedCachedResponsesByRequest valueForKey:cacheKey];
	if (cachedResponse) {
		return cachedResponse;
	}
	
	return nil;
}

- (void)storeCachedResponse:(NSCachedURLResponse *)cachedResponse forRequest:(NSURLRequest *)request {
	NSString *cacheKey = AFURLCacheKeyForNSURLRequest(request);
	[self.keyedCachedResponsesByRequest setObject:cachedResponse forKey:cacheKey];
    [self.cachedRequests addObject:cacheKey];
}

- (void)removeCachedResponseForRequest:(NSURLRequest *)request {
    NSString *cacheKey = AFURLCacheKeyForNSURLRequest(request);
	[self.keyedCachedResponsesByRequest removeObjectForKey:cacheKey];
	[self.cachedRequests removeObject:cacheKey];
}

- (void)removeAllCachedResponses {
	[self.keyedCachedResponsesByRequest removeAllObjects];
    [self.cachedRequests removeAllObjects];
}

- (NSUInteger)currentMemoryUsage {
	return [[[self.keyedCachedResponsesByRequest allValues] valueForKeyPath:@"@sum.data.length"] integerValue];
}

#pragma mark - Maintenance

- (void)periodicMaintenance {
    [self.periodicMaintenanceOperation cancel];
    self.periodicMaintenanceOperation = nil;
    if ([self currentMemoryUsage] > [self memoryCapacity]) {
        self.periodicMaintenanceOperation = [[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(sweepMemoryCache) object:nil] autorelease];
        [self.periodicMaintenanceOperationQueue addOperation:self.periodicMaintenanceOperation];
    }
}

- (void)sweepMemoryCache {
	NSArray *sortedCachedRequests = [[self.cachedRequests allObjects] sortedArrayUsingComparator:^(id obj1, id obj2) { 
		NSUInteger count1 = [self.cachedRequests countForObject:obj1];
		NSUInteger count2 = [self.cachedRequests countForObject:obj2];
		
		if (count1 > count2) {
			return NSOrderedDescending;
		} else if (count1 < count2) {
			return NSOrderedAscending;
		} else {
			return NSOrderedSame;
		}
	}];
	
	NSUInteger memoryDeficit = [self currentMemoryUsage] - [self memoryCapacity];
	NSString *cacheKey = nil;
	NSEnumerator *enumerator = [sortedCachedRequests reverseObjectEnumerator];
	while (memoryDeficit > 0 && (cacheKey = [enumerator nextObject])) {
		NSCachedURLResponse *response = (NSCachedURLResponse *)[self.keyedCachedResponsesByRequest objectForKey:cacheKey];
		memoryDeficit -= [[response data] length];
		[self.keyedCachedResponsesByRequest removeObjectForKey:cacheKey];
	}
	
	self.cachedRequests = [NSCountedSet setWithArray:[self.keyedCachedResponsesByRequest allKeys]];	
}

@end
