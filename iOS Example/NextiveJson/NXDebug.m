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

#import "NXDebug.h"
#include <unistd.h>
#include <sys/sysctl.h>

bool _NXAmIBeingDebugged(void);
void _NXDebugBreak(void);


// Returns true if the current process is being debugged (either
// running under the debugger or has a debugger attached post facto).
// From http://developer.apple.com/mac/library/qa/qa2004/qa1361.html, midly edited for style.
bool _NXAmIBeingDebugged(void)
{
    int                 mib[4];
    struct kinfo_proc   info;
	
    // Initialize the flags so that, if sysctl fails for some bizarre
    // reason, we get a predictable result.
	
    info.kp_proc.p_flag = 0;
	
    // Initialize mib, which tells sysctl the info we want, in this case
    // we're looking for information about a specific process ID.
	
    mib[0] = CTL_KERN;
    mib[1] = KERN_PROC;
    mib[2] = KERN_PROC_PID;
    mib[3] = getpid();
	
    // Call sysctl.
	
    size_t size = sizeof(info);
    int junk = sysctl(mib, sizeof(mib) / sizeof(*mib), &info, &size, NULL, 0);
    ASSERT(junk == 0);
	UNUSED(junk);
	
    // We're being debugged if the P_TRACED flag is set.
    return ( (info.kp_proc.p_flag & P_TRACED) != 0 );
}

// If the app is running attached to a debugger, it breaks. If not, it crashes.
void _NXDebugBreak(void) 
{
	if (!_NXAmIBeingDebugged()) 
	{
		abort();
	}
	kill(getpid(), SIGINT);
}

void _NXAssert(NSString* message, const char* filename, int lineNumber, const char* functionName)
{
	NSLog(@"***************************************************************************");
	NSLog(@"Assertion failed at %s: %@", functionName, message);
	NSLog(@"%s:%d", filename, lineNumber);
	NSLog(@"***************************************************************************");
	[NXDebug printCallStack];
	NSLog(@"***************************************************************************");
	_NXDebugBreak();
}

//TODO: research __attribute__ ((format (printf, 1, 2)))
void _NXTrace(NSString* format, ...) 
{
    va_list ap;
	
    va_start (ap, format);
	format = [format stringByAppendingString: @"\n"];
    NSString* body =  [[NSString alloc] initWithFormat:format arguments:ap];
    va_end (ap);
    
	fprintf(stderr, "%s", [body UTF8String]);
	
    NXReleaseAndNil(body);
}

void _NXDie(NSString* reason, const char* filename, int line, const char* functionName)
{
	NSLog(@"Impossible situation: %@", reason);
	NSLog(@"%s:%d:1 [%s]", filename, line, functionName);
	[NXDebug printCallStack];
	_NXDebugBreak();
}



@implementation NXDebug

+(void)printCallStack 
{
	// callStackSymbols is available on iOS4+ only
	if ([[NSThread class] respondsToSelector:@selector(callStackSymbols)]) 
	{
		NSArray *stack = [[NSThread class] performSelector:@selector(callStackSymbols)];
		
		for (NSString* line in stack) 
		{
			NSLog(@"%@", line);
		}
		
	} 
	else 
	{
		NSLog(@"Stack trace unavailable");
	}
}

@end
