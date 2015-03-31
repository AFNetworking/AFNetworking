//
//  AppDelegate.m
//  iOS Test Application
//
//  Created by Brian Gerstle on 3/31/15.
//  Copyright (c) 2015 AFNetworking. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

#define NEW_IF_AVAILABLE(t) (NSClassFromString(@#t) ? [t new] : nil)

#define COMPILE_DATA_TASK_CODE 0

#if COMPILE_DATA_TASK_CODE
#warning Setting COMPILE_DATA_TASK_CODE to 1 will cause the app to crash with a dyld error!
#endif

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [self sessionIfAvailable];
    [self abstractTaskIfAvailable];
    [self taskStateIfAvailable];

#if COMPILE_DATA_TASK_CODE
    [self dataTaskIfAvailable];
#endif

    return YES;
}

- (NSURLSession*)sessionIfAvailable {
    return NEW_IF_AVAILABLE(NSURLSession);
}

- (NSURLSessionTask*)abstractTaskIfAvailable {
    return NEW_IF_AVAILABLE(NSURLSessionTask);
}

- (NSURLSessionTaskState)taskStateIfAvailable {
    return NSClassFromString(@"NSURLSession") ? NSURLSessionTaskStateRunning : 0;
}

#if COMPILE_DATA_TASK_CODE
- (NSURLSessionDataTask*)dataTaskIfAvailable {
    return NEW_IF_AVAILABLE(NSURLSessionDataTask);
}
#endif

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
