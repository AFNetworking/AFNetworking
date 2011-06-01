// AFHTTPOperation.m
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

#import "AFHTTPOperation.h"
#import "JSONKit.h"

NSString * const AFHTTPOperationDidStartNotification = @"com.alamofire.http-operation.start";
NSString * const AFHTTPOperationDidSucceedNotification = @"com.alamofire.http-operation.success";
NSString * const AFHTTPOperationDidFailNotification = @"com.alamofire.http-operation.failure";

NSString * const AFHTTPOperationParsedDataErrorKey = @"com.alamofire.http-operation.error.parsed-data";

@implementation AFHTTPOperation
@synthesize callback = _callback;

+ (id)operationWithRequest:(NSURLRequest *)urlRequest callback:(AFHTTPOperationCallback *)callback {
    return [[[self alloc] initWithRequest:urlRequest callback:callback] autorelease];
}

- (id)initWithRequest:(NSURLRequest *)urlRequest callback:(AFHTTPOperationCallback *)callback {
    self = [super initWithRequest:urlRequest];
    if (!self) {
		return nil;
    }
	
	self.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/plain", nil];
	self.callback = callback;	
	
    return self;
}

- (void)dealloc {
	[_callback release];
	[super dealloc];
}

- (NSString *)responseString {
    return [[[NSString alloc] initWithData:self.responseBody encoding:NSUTF8StringEncoding] autorelease];
}

#pragma mark - QRunLoopOperation

- (void)operationDidStart {
	[super operationDidStart];
	[[NSNotificationCenter defaultCenter] postNotificationName:AFHTTPOperationDidStartNotification object:self];
}

- (void)finishWithError:(NSError *)error {
	[super finishWithError:error];
    
    NSDictionary *data = nil;
    if (self.contentTypeAcceptable) {
        if ([[self.lastResponse MIMEType] isEqualToString:@"application/json"]) {
            NSError *jsonError = nil;
            data = [[JSONDecoder decoder] parseJSONData:self.responseBody error:&jsonError];
        }
    }
    
    if (self.statusCodeAcceptable) {		
        [[NSNotificationCenter defaultCenter] postNotificationName:AFHTTPOperationDidSucceedNotification object:self];
        
        if(self.callback.successBlock) {
            self.callback.successBlock(self.lastRequest, self.lastResponse, data);
        }
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:AFHTTPOperationDidFailNotification object:self];
        
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[error userInfo]];
        [userInfo setValue:[NSHTTPURLResponse localizedStringForStatusCode:[self.lastResponse statusCode]] forKey:NSLocalizedDescriptionKey];
        [userInfo setValue:[[self.lastRequest URL] absoluteString] forKey:NSURLErrorFailingURLStringErrorKey];
        [userInfo setValue:data forKey:AFHTTPOperationParsedDataErrorKey];
        
        error = [[[NSError alloc] initWithDomain:NSURLErrorDomain code:[self.lastResponse statusCode] userInfo:userInfo] autorelease];
        
        if (self.callback.errorBlock) {
            self.callback.errorBlock(self.lastRequest, self.lastResponse, error);
        }
    }
}

@end

#pragma mark - AFHTTPOperationCallback

@implementation AFHTTPOperationCallback
@dynamic successBlock, errorBlock;
@end
