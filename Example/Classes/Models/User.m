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
#import "AFHTTPRequestOperation.h"

NSString * const kUserProfileImageDidLoadNotification = @"com.alamofire.user.profile-image.loaded";

@interface User ()
@property (readwrite, nonatomic, assign) NSUInteger userID;
@property (readwrite, nonatomic, copy) NSString *username;
@property (readwrite, nonatomic, copy) NSString *avatarImageURLString;

#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED
@property (readwrite, nonatomic, strong) AFHTTPRequestOperation *avatarImageRequestOperation;
#endif
@end

@implementation User

- (instancetype)initWithAttributes:(NSDictionary *)attributes {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.userID = (NSUInteger)[[attributes valueForKeyPath:@"id"] integerValue];
    self.username = [attributes valueForKeyPath:@"username"];
    self.avatarImageURLString = [attributes valueForKeyPath:@"avatar_image.url"];
    
    return self;
}

- (NSURL *)avatarImageURL {
    return [NSURL URLWithString:self.avatarImageURLString];
}

#pragma mark -

#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED

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
	if (!_profileImage && !_avatarImageRequestOperation) {
        NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:self.avatarImageURL];
        [mutableRequest setValue:@"image/*" forHTTPHeaderField:@"Accept"];
        AFHTTPRequestOperation *imageRequestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:mutableRequest];
        imageRequestOperation.responseSerializer = [AFImageResponseSerializer serializer];
        [imageRequestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, NSImage *responseImage) {
            self.profileImage = responseImage;

			_avatarImageRequestOperation = nil;

            [[NSNotificationCenter defaultCenter] postNotificationName:kUserProfileImageDidLoadNotification object:self userInfo:nil];
        } failure:nil];

		[imageRequestOperation setCacheResponseBlock:^NSCachedURLResponse *(NSURLConnection *connection, NSCachedURLResponse *cachedResponse) {
			return [[NSCachedURLResponse alloc] initWithResponse:cachedResponse.response data:cachedResponse.data userInfo:cachedResponse.userInfo storagePolicy:NSURLCacheStorageAllowed];
		}];

		_avatarImageRequestOperation = imageRequestOperation;
		
        [[[self class] sharedProfileImageRequestOperationQueue] addOperation:_avatarImageRequestOperation];
	}
	
	return _profileImage;
}

#endif

@end
