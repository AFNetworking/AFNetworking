// Tweet.m
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

#import "Tweet.h"
#import "User.h"

#import "AFTwitterAPIClient.h"

@implementation Tweet {
@private
    NSUInteger _tweetID;
    __strong NSString *_text;
    __strong User *_user;
}

@synthesize tweetID = _tweetID;
@synthesize text = _text;
@synthesize user = _user;

- (id)initWithAttributes:(NSDictionary *)attributes {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _tweetID = [[attributes valueForKeyPath:@"id"] integerValue];
    _text = [attributes valueForKeyPath:@"text"];
    
    _user = [[User alloc] initWithAttributes:[attributes valueForKeyPath:@"user"]];
    
    return self;
}

#pragma mark -

+ (void)publicTimelineTweetsWithBlock:(void (^)(NSArray *tweets))block {
    [[AFTwitterAPIClient sharedClient] getPath:@"statuses/public_timeline.json" parameters:[NSDictionary dictionaryWithObject:@"false" forKey:@"include_entities"] success:^(AFHTTPRequestOperation *operation, id JSON) {
        NSMutableArray *mutableTweets = [NSMutableArray arrayWithCapacity:[JSON count]];
        for (NSDictionary *attributes in JSON) {
            Tweet *tweet = [[Tweet alloc] initWithAttributes:attributes];
            [mutableTweets addObject:tweet];
        }
        
        if (block) {
            block([NSArray arrayWithArray:mutableTweets]);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        
        [[[UIAlertView alloc] initWithTitle:@"Error" message:[error localizedDescription] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] show];
        
        if (block) {
            block(nil);
        }
    }];
}

@end
