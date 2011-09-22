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

@interface AFNetworkActivityIndicatorManager ()
@property (readwrite, nonatomic, assign) NSInteger activityCount;
@end

@implementation AFNetworkActivityIndicatorManager
@synthesize activityCount = _activityCount;

+ (AFNetworkActivityIndicatorManager *)sharedManager {
    static AFNetworkActivityIndicatorManager *_sharedManager = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedManager = [[AFNetworkActivityIndicatorManager alloc] init];
    });
    
    return _sharedManager;
}

- (void)setActivityCount:(NSInteger)activityCount {
    [self willChangeValueForKey:@"activityCount"];
    _activityCount = MAX(activityCount, 0);
    [self didChangeValueForKey:@"activityCount"];

    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:self.activityCount > 0];
}

- (void)incrementActivityCount {
    @synchronized(self) {
        self.activityCount += 1;
    }
}

- (void)decrementActivityCount {
    @synchronized(self) {
        self.activityCount -= 1;
    }
}

@end
