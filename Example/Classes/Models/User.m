// User.m
//
// Copyright (c) 2011–2016 Alamofire Software Foundation ( http://alamofire.org/ )
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
#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED
//#import "AFHTTPRequestOperation.h"
#endif

NSString * const kUserProfileImageDidLoadNotification = @"com.alamofire.user.profile-image.loaded";

@interface User ()
@property (readwrite, nonatomic, assign) NSUInteger userID;
@property (readwrite, nonatomic, copy) NSString *username;
@property (readwrite, nonatomic, copy) NSString *avatarImageURLString;

//#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED
//@property (readwrite, nonatomic, strong) AFHTTPRequestOperation *avatarImageRequestOperation;
//#endif
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

//+ (NSOperationQueue *)sharedProfileImageRequestOperationQueue {
//    static NSOperationQueue *_sharedProfileImageRequestOperationQueue = nil;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        _sharedProfileImageRequestOperationQueue = [[NSOperationQueue alloc] init];
//        [_sharedProfileImageRequestOperationQueue setMaxConcurrentOperationCount:8];
//    });
//    
//    return _sharedProfileImageRequestOperationQueue;
//}

- (NSImage *)profileImage {
    return nil;
//	if (!_profileImage && !_avatarImageRequestOperation) {
//        NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:self.avatarImageURL];
//        [mutableRequest setValue:@"image/*" forHTTPHeaderField:@"Accept"];
//        AFHTTPRequestOperation *imageRequestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:mutableRequest];
//        imageRequestOperation.responseSerializer = [AFImageResponseSerializer serializer];
//        [imageRequestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, NSImage *responseImage) {
//            self.profileImage = responseImage;
//
//			_avatarImageRequestOperation = nil;
//
//            [[NSNotificationCenter defaultCenter] postNotificationName:kUserProfileImageDidLoadNotification object:self userInfo:nil];
//        } failure:nil];
//
//		[imageRequestOperation setCacheResponseBlock:^NSCachedURLResponse *(NSURLConnection *connection, NSCachedURLResponse *cachedResponse) {
//			return [[NSCachedURLResponse alloc] initWithResponse:cachedResponse.response data:cachedResponse.data userInfo:cachedResponse.userInfo storagePolicy:NSURLCacheStorageAllowed];
//		}];
//
//		_avatarImageRequestOperation = imageRequestOperation;
//		
//        [[[self class] sharedProfileImageRequestOperationQueue] addOperation:_avatarImageRequestOperation];
//	}
//	
//	return _profileImage;
}

#endif

@end

@implementation User (NSCoding)

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:(NSInteger)self.userID forKey:@"AF.userID"];
    [aCoder encodeObject:self.username forKey:@"AF.username"];
    [aCoder encodeObject:self.avatarImageURLString forKey:@"AF.avatarImageURLString"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.userID = (NSUInteger)[aDecoder decodeIntegerForKey:@"AF.userID"];
    self.username = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"AF.username"];
    self.avatarImageURLString = [aDecoder decodeObjectOfClass:[User class] forKey:@"AF.avatarImageURLString"];
    
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

@end
