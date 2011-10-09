//
//  DetailViewController.m
//  AFNetworkingXMLRPCExample
//
//  Created by Jorge Bernal on 10/8/11.
//  Copyright (c) 2011 Automattic. All rights reserved.
//

#import "DetailViewController.h"
#import "UIImageView+AFNetworking.h"

#import <CommonCrypto/CommonDigest.h> // Need to import for CC_MD5 access

NSString *md5(NSString *str) {
    const char *cStr = [str UTF8String];
    unsigned char result[16];
    CC_MD5( cStr, strlen(cStr), result ); // This is the md5 call
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3], 
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];  
}

@interface DetailViewController ()
- (void)configureView;
@end

@implementation DetailViewController

@synthesize detailItem = _detailItem;
@synthesize contentWebView, authorLabel, emailLabel, gravatarView;

- (void)dealloc
{
    [_detailItem release];
    self.contentWebView = nil;
    self.authorLabel = nil;
    self.emailLabel = nil;
    self.gravatarView = nil;
    [super dealloc];
}

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        [_detailItem release]; 
        _detailItem = [newDetailItem retain]; 

        // Update the view.
        [self configureView];
    }
}

- (void)configureView
{
    // Update the user interface for the detail item.

    if (self.detailItem) {
        NSString *author_email = [self.detailItem objectForKey:@"author_email"];
        if (author_email && [author_email length] > 0) {
            NSString *gravatarUrl = [NSString stringWithFormat:@"http://www.gravatar.com/avatar/%@.jpg?s=96", md5(author_email)];
                                     
            [self.gravatarView setImageWithURL:[NSURL URLWithString:gravatarUrl]];
            self.emailLabel.text = author_email;
        }
        self.authorLabel.text = [self.detailItem objectForKey:@"author"];
        [self.contentWebView loadHTMLString:[self.detailItem objectForKey:@"content"] baseURL:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Detail", @"Detail");
    }
    return self;
}
							
@end
