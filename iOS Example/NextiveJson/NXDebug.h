/*
 
 Copyright (c) 2011 Nextive LLC
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
 associated documentation files (the "Software"), to deal in the Software without restriction,
 including without limitation the rights to use, copy, modify, merge, publish, distribute,
 sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial
 portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
 NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
 OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 Created by Martin Adoue (martin@nextive.com) and Hernan Pelassini (hernan@nextive.com)
 
 */

#import <Foundation/Foundation.h>

/**
 
 Small class with helper methods, only useful for debugging.
 
 */
@interface NXDebug : NSObject 
{
	
}
/// Prints the call stack up to the call. only in supported platforms.
+(void)printCallStack;

@end


#ifdef __clang__
	#define NOTNULL(...) __attribute__((nonnull (__VA_ARGS__)))
	#define NORETURN __attribute__((analyzer_noreturn))
#else
	#define NOTNULL(...) 
	#define NORETURN 
#endif


// Prints a message and the call stack to the console, and calls NXDebugBreak
// INTERNAL. Do not use directly.
void _NXAssert(NSString *message, const char *filename, int lineNumber, const char *functionName) NOTNULL(1, 2, 4) NORETURN;

// Prints a formatted string to the console.
// INTERNAL. Do not use directly.
void _NXTrace(NSString *format, ...) NOTNULL(1);

// INTERNAL. Do not use directly.
void _NXDie(NSString *reason, const char *filename, int line, const char *function) NOTNULL(1, 2, 4) NORETURN;


/*
 Use this when you have a variable that is only used on certain configurations (tipically DEBUG).
 It has zero runtime cost.
 
 Example:
 
 ----------------------------
 int length = [string length];
 ASSERT(length > 0);
 // If we never use length again, the compiler will complain in release builds.
 UNUSED(variable);
 ----------------------------

 Another use is to shut up the compiler when we don't use a parameter.
 
 */
#define UNUSED(variable) ((void)variable)


/*
 ASSERT is a nicer version of NSAssertX, with the added benefit that it does nothing on release builds.
 Oh, one more thing. If you're running on the debugger, you can continue. Yep, it's like a good old conditional breakpoint.
 */
#ifndef DEBUG
	#define ASSERT(condition) do { } while (0);
#else
	#define ASSERT(condition) do { if(!(condition)) { _NXAssert([NSString stringWithCString:#condition encoding:NSUTF8StringEncoding], __FILE__, __LINE__, __PRETTY_FUNCTION__); } } while (0);
#endif

/*
 TRACE is a nicer version of NSLog, with the added benefit that it does nothing on release builds.
 
 Usage: 
 
 TRACE();
 TRACE(@"Hello world");
 TRACE(@"The value is: %d", value);
 TRACE("The value is: %d", value);
 
 */
#ifndef DEBUG
#define TRACE(...) do { } while (0);
#else
#define TRACE(format, ...) do { _NXTrace((@"%s:%d:1 [%s] " format), __FILE__, __LINE__, __PRETTY_FUNCTION__, ##__VA_ARGS__); } while (0);
#endif

// Use this when you want to signal an impossible or unexpected situation.
// It's similar to ASSERT, but it remains on release builds.
// Prints the reason, the location of the failure, and the call stack to the console.
// If its running under a debugger, it breaks. Else, it exits.
// NOTE: it only prints the call stack on iOS4+
#define DIE(reason) do { _NXDie(reason, __FILE__, __LINE__, __PRETTY_FUNCTION__); } while (0);


// Short and clear way to make sure a variable is of the expected type.
#define ASSERT_CLASS(x, y) ASSERT([x isKindOfClass:[y class]])
#define ASSERT_CLASS_OR_NULL(x, y) ASSERT(x == nil || [(id)x isKindOfClass:[y class]])
#define ASSERT_PROTOCOL(x, y) ASSERT([x conformsToProtocol:@protocol(y)]);

// Release and set to nil in a single line.
#define	NXReleaseAndNil(x) { [x release], x = nil; }


