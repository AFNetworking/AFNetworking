// AFCallback.m
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

#import "AFCallback.h"

@interface AFCallback ()
@property (readwrite, nonatomic, copy) id successBlock;
@property (readwrite, nonatomic, copy) id errorBlock;
@end

@implementation AFCallback
@synthesize successBlock = _successBlock;
@synthesize errorBlock = _errorBlock;

+ (id)callbackWithSuccess:(id)success {
	return [self callbackWithSuccess:success error:nil];
}

+ (id)callbackWithSuccess:(id)success error:(id)error {
	id callback = [[[self alloc] init] autorelease];
	[callback setSuccessBlock:success];
	[callback setErrorBlock:error];
	
	return callback;
}

- (id)init {
	if ([self class] == [AFCallback class]) {
		[NSException raise:NSInternalInconsistencyException format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
	}
	
	return [super init];
}

- (void)dealloc {
	[_successBlock release];
	[_errorBlock release];
	[super dealloc];
}

@end