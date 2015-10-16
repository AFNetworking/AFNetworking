//  TodayViewController.m
//
//  Copyright (c) 2015 Brian Nickel
//
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

#import <NotificationCenter/NotificationCenter.h>
#import "TodayViewController.h"
#import "Post.h"
#import "User.h"
@import AFNetworking;

@interface TodayViewController () <NCWidgetProviding>
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *bodyLabel;
@property (nonatomic, strong) Post *post;
@end

@implementation TodayViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSURLCache *URLCache = [[NSURLCache alloc] initWithMemoryCapacity:4 * 1024 * 1024 diskCapacity:20 * 1024 * 1024 diskPath:nil];
    [NSURLCache setSharedURLCache:URLCache];
    self.post = [self loadSavedPost];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    [Post globalTimelinePostsWithBlock:^(NSArray *posts, NSError *error) {
        if (!error) {

            self.post = posts.firstObject;
            [self savePost:self.post];

            if (completionHandler) {
                completionHandler(self.post != nil ? NCUpdateResultNewData : NCUpdateResultNoData);
            }

        } else {
            if (completionHandler) {
                completionHandler(NCUpdateResultFailed);
            }
        }
    }];
}

- (void)setPost:(Post *)post {
    _post = post;

    self.titleLabel.hidden = post == nil;
    self.bodyLabel.hidden = post == nil;
    self.imageView.hidden = post == nil;

    if (post == nil) {
        return;
    }

    self.titleLabel.text = _post.user.username;
    self.bodyLabel.text = _post.text;
    [self.imageView setImageWithURL:_post.user.avatarImageURL placeholderImage:[UIImage imageNamed:@"profile-image-placeholder"]];
}

- (void)savePost:(Post *)post {

    if (post == nil) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"AF.post"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        return;
    }

    NSData *postData = [NSKeyedArchiver archivedDataWithRootObject:post];
    [[NSUserDefaults standardUserDefaults] setObject:postData forKey:@"AF.post"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (Post *)loadSavedPost {
    NSData *postData = [[NSUserDefaults standardUserDefaults] objectForKey:@"AF.post"];
    if (postData == nil || ![postData isKindOfClass:[NSData class]]) {
        return nil;
    }

    return [NSKeyedUnarchiver unarchiveObjectWithData:postData];
}

@end
