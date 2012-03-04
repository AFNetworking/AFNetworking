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

#import "NSError+Extensions.h"


@implementation NSError(Extensions)
+(NSError*)errorWithDomain:(NSString*)domain code:(NSInteger)code description:(NSString*)description
{
	
	ASSERT(domain);
	ASSERT(description);
	ASSERT_CLASS(domain, NSString);
	ASSERT_CLASS(description, NSString);
	ASSERT([domain length] > 0);
	ASSERT([description length] > 0);
	ASSERT(code != 0); 
	
	NSMutableDictionary* errorDict = [NSMutableDictionary dictionary];
	[errorDict setObject:description forKey:NSLocalizedDescriptionKey];			
	return [NSError errorWithDomain:domain code:code userInfo:errorDict];
}

@end
