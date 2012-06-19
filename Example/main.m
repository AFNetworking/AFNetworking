//
//  main.m
//  AFNetworking-Mac-Example
//
//  Created by Mattt Thompson on 12/06/19.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#if __IPHONE_OS_VERSION_MIN_REQUIRED
  #import <UIKit/UIKit.h>

  int main(int argc, char *argv[]) {
      @autoreleasepool {
          int retVal = UIApplicationMain(argc, argv, @"UIApplication", @"AppDelegate");
          return retVal;
      }
  }
#else
  #import <Cocoa/Cocoa.h>

  int main(int argc, char *argv[]) {
      return NSApplicationMain(argc, (const char **)argv);
  }
#endif
