// User.m
//
// Copyright (c) 2012 Mattt Thompson (http://mattt.me/)
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

#import "User.h"
#import "AFImageRequestOperation.h"

NSString * const kUserProfileImageDidLoadNotification = @"com.alamofire.user.profile-image.loaded";

@interface User ()
#if __MAC_OS_X_VERSION_MIN_REQUIRED
+ (NSOperationQueue *)sharedProfileImageRequestOperationQueue;
#endif
@end

@implementation User {
@private
    __strong NSString *_profileImageURLString;
    __strong AFImageRequestOperation *_profileImageRequestOperation;
}

@synthesize userID = _userID;
@synthesize username = _username;

- (id)initWithAttributes:(NSDictionary *)attributes {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _userID = [[attributes valueForKeyPath:@"id"] integerValue];
    _username = [attributes valueForKeyPath:@"screen_name"];
    _profileImageURLString = [attributes valueForKeyPath:@"profile_image_url_https"];
    
    return self;
}

- (NSURL *)profileImageURL {
    return [NSURL URLWithString:_profileImageURLString];
}

#if __MAC_OS_X_VERSION_MIN_REQUIRED

@synthesize profileImage = _profileImage;

+ (NSOperationQueue *)sharedProfileImageRequestOperationQueue {
    static NSOperationQueue *_sharedProfileImageRequestOperationQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedProfileImageRequestOperationQueue = [[NSOperationQueue alloc] init];
        [_sharedProfileImageRequestOperationQueue setMaxConcurrentOperationCount:8];
    });
    
    return _sharedProfileImageRequestOperationQueue;
}

- (NSImage *)profileImage {
	if (!_profileImage && !_profileImageRequestOperation) {
		_profileImageRequestOperation = [AFImageRequestOperation imageRequestOperationWithRequest:[NSURLRequest requestWithURL:self.profileImageURL] success:^(NSImage *image) {
			self.profileImage = image;
            
			_profileImageRequestOperation = nil;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kUserProfileImageDidLoadNotification object:self userInfo:nil];
		}];
        
		[_profileImageRequestOperation setCacheResponseBlock:^NSCachedURLResponse *(NSURLConnection *connection, NSCachedURLResponse *cachedResponse) {
			return [[NSCachedURLResponse alloc] initWithResponse:cachedResponse.response data:cachedResponse.data userInfo:cachedResponse.userInfo storagePolicy:NSURLCacheStorageAllowed];
		}];
		
        [[[self class] sharedProfileImageRequestOperationQueue] addOperation:_profileImageRequestOperation];
	}
	
	return _profileImage;
}

#endif

@end
