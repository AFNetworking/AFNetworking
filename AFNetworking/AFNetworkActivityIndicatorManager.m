// AFNetworkActivityIndicatorManager.m
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

#import "AFNetworkActivityIndicatorManager.h"

#import "AFHTTPRequestOperation.h"
#import <libkern/OSAtomic.h>

#if __IPHONE_OS_VERSION_MIN_REQUIRED
static NSTimeInterval const kAFNetworkActivityIndicatorInvisibilityDelay = 0.25;

@interface AFNetworkActivityIndicatorManager ()
@property (readwrite, nonatomic, assign) NSInteger activityCount;
@property (readwrite, nonatomic, retain) NSTimer *activityIndicatorVisibilityTimer;
@property (readonly, getter = isNetworkActivityIndicatorVisible) BOOL networkActivityIndicatorVisible;

- (void)updateNetworkActivityIndicatorVisibility;
@end

@implementation AFNetworkActivityIndicatorManager
@synthesize activityCount = _activityCount;
@synthesize activityIndicatorVisibilityTimer = _activityIndicatorVisibilityTimer;
@synthesize enabled = _enabled;
@dynamic networkActivityIndicatorVisible;

+ (AFNetworkActivityIndicatorManager *)sharedManager {
    static AFNetworkActivityIndicatorManager *_sharedManager = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedManager = [[self alloc] init];
    });
    
    return _sharedManager;
}

- (id)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(incrementActivityCount) name:AFNetworkingOperationDidStartNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(decrementActivityCount) name:AFNetworkingOperationDidFinishNotification object:nil];
        
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_activityIndicatorVisibilityTimer invalidate];
    [_activityIndicatorVisibilityTimer release]; _activityIndicatorVisibilityTimer = nil;
    
    [super dealloc];
}

- (void)updateNetworkActivityIndicatorVisibilityDelayed {
    if (self.enabled) {
        // Delay hiding of activity indicator for a short interval, to avoid flickering
        if (![self isNetworkActivityIndicatorVisible]) {
            [self.activityIndicatorVisibilityTimer invalidate];
            self.activityIndicatorVisibilityTimer = [NSTimer timerWithTimeInterval:kAFNetworkActivityIndicatorInvisibilityDelay target:self selector:@selector(updateNetworkActivityIndicatorVisibility) userInfo:nil repeats:NO];
            [[NSRunLoop currentRunLoop] addTimer:self.activityIndicatorVisibilityTimer forMode:NSRunLoopCommonModes];
        } else {
            [self updateNetworkActivityIndicatorVisibility];
        }
    }
}

- (BOOL)isNetworkActivityIndicatorVisible {
    return _activityCount > 0;
}

- (void)updateNetworkActivityIndicatorVisibility {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:[self isNetworkActivityIndicatorVisible]];
    });
}

// Not exposed, but used if activityCount is set via KVC.
- (void)setActivityCount:(NSInteger)activityCount {
	#ifdef __clang__
		// use clang's builtin atomic-swap method
		__sync_swap(&_activityCount, activityCount);
	#else
		#ifdef __GNUC__
			// use GCC's builtin atomic-swap method
			__sync_val_compare_and_swap(&_activityCount, _activityCount, activityCount)
		#else
			// hope for the best
			#warning Unsupported compiler. AFNetworkActivityIndicatorManager.activityCount may not be set atomically.
			_activityCount = activityCount;
		#endif
	#endif
    [self updateNetworkActivityIndicatorVisibilityDelayed];
}

- (void)incrementActivityCount {
    [self willChangeValueForKey:@"activityCount"];
    OSAtomicIncrement32((int32_t*)&_activityCount);
    [self didChangeValueForKey:@"activityCount"];
    [self updateNetworkActivityIndicatorVisibilityDelayed];
}

- (void)decrementActivityCount {
    [self willChangeValueForKey:@"activityCount"];
    bool success;
    do {
        int32_t currentCount = _activityCount;
        success = OSAtomicCompareAndSwap32(currentCount, MIN(currentCount - 1, currentCount), &_activityCount);
    } while(!success);
    [self didChangeValueForKey:@"activityCount"];
    [self updateNetworkActivityIndicatorVisibilityDelayed];
}

+ (NSSet *)keyPathsForValuesAffectingIsNetworkActivityIndicatorVisible {
    return [NSSet setWithObject:@"activityCount"];
}

@end

#endif
