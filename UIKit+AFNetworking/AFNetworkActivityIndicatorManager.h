// AFNetworkActivityIndicatorManager.h
//
// Copyright (c) 2013 AFNetworking (http://afnetworking.com)
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

#import <Foundation/Foundation.h>

#import <Availability.h>

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)

#import <UIKit/UIKit.h>

/**
 `AFNetworkActivityIndicatorManager` manages the state of the network activity indicator in the status bar. When enabled, it will listen for notifications indicating that a network request operation has started or finished, and start or stop animating the indicator accordingly. The number of active requests is incremented and decremented much like a stack or a semaphore, and the activity indicator will animate so long as that number is greater than zero.

 You should enable the shared instance of `AFNetworkActivityIndicatorManager` when your application finishes launching. In `AppDelegate application:didFinishLaunchingWithOptions:` you can do so with the following code:

    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];

 By setting `isNetworkActivityIndicatorVisible` to `YES` for `sharedManager`, the network activity indicator will show and hide automatically as requests start and finish. You should not ever need to call `incrementActivityCount` or `decrementActivityCount` yourself.

 See the Apple Human Interface Guidelines section about the Network Activity Indicator for more information:
 http://developer.apple.com/library/iOS/#documentation/UserExperience/Conceptual/MobileHIG/UIElementGuidelines/UIElementGuidelines.html#//apple_ref/doc/uid/TP40006556-CH13-SW44
 */
@interface AFNetworkActivityIndicatorManager : NSObject

/**
 A Boolean value indicating whether the manager is enabled.

 If YES, the manager will change status bar network activity indicator according to network operation notifications it receives. The default value is NO.
 */
@property (nonatomic, assign, getter = isEnabled) BOOL enabled;

/**
 A Boolean value indicating whether the network activity indicator is currently displayed in the status bar.
 */
@property (readonly, nonatomic, assign) BOOL isNetworkActivityIndicatorVisible;

/**
 Returns the shared network activity indicator manager object for the system.

 @return The systemwide network activity indicator manager.
 */
+ (instancetype)sharedManager;

/**
 Increments the number of active network requests. If this number was zero before incrementing, this will start animating the status bar network activity indicator.
 */
- (void)incrementActivityCount;

/**
 Decrements the number of active network requests. If this number becomes zero after decrementing, this will stop animating the status bar network activity indicator.
 */
- (void)decrementActivityCount;

@end

#endif
