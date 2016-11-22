//
//  ViewController.m
//  DebugTest
//
//  Created by snowimba on 16/1/14.
//  Copyright © 2016年 snowimba. All rights reserved.
//

#import "ViewController.h"
#import <UIWebView+AFNetworking.h>
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}
- (IBAction)Test01:(UIButton*)sender
{

    UIWebView* webView = [[UIWebView alloc] init];

    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://github.com"]];

    //    [webView loadRequest:<#(nonnull NSURLRequest *)#> progress:<#(NSProgress *__autoreleasing  _Nullable * _Nullable)#> success:<#^NSString * _Nonnull(NSHTTPURLResponse * _Nonnull response, NSString * _Nonnull HTML)success#> failure:<#^(NSError * _Nonnull error)failure#>]

    //  progress:<#(NSProgress *__autoreleasing  _Nullable * _Nullable)#>
    //  progress Nullable
    //  progress:NULL--------crash

    [webView loadRequest:request progress:NULL success:^NSString* _Nonnull(NSHTTPURLResponse* _Nonnull response, NSString* _Nonnull HTML) {
        NSLog(@"OK");
        return HTML;
    }
        failure:^(NSError* _Nonnull error) {

            NSLog(@"%@", error);
        }];
}

- (IBAction)Test02:(UIButton*)sender
{

    UIWebView* webView = [[UIWebView alloc] init];

    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://github.com"]];

    //  progress:nil------crash
    [webView loadRequest:request progress:nil success:^NSString* _Nonnull(NSHTTPURLResponse* _Nonnull response, NSString* _Nonnull HTML) {
        NSLog(@"OK");
        return HTML;
    }
        failure:^(NSError* _Nonnull error) {

            NSLog(@"%@", error);
        }];
}

- (IBAction)Test03:(UIButton*)sender
{
    UIWebView* webView = [[UIWebView alloc] init];

    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://github.com"]];

    NSProgress* progress = nil;

    //  progress:&progress-------OK
    [webView loadRequest:request progress:&progress success:^NSString* _Nonnull(NSHTTPURLResponse* _Nonnull response, NSString* _Nonnull HTML) {
        NSLog(@"OK");
        return HTML;
    }
        failure:^(NSError* _Nonnull error) {

            NSLog(@"%@", error);
        }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
