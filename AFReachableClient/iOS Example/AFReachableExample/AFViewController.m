// AFViewController.m
//
// Copyright (c) 2011 Kevin Harwood
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

#import "AFViewController.h"
#import "YWWeatherAPIClient.h"

@interface AFViewController (){
    NSInteger completedRequests_;
    NSInteger failedRequests_;
}
@end

@implementation AFViewController
@synthesize completeLabel;
@synthesize failedLabel;

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
    [completeLabel setText:@"0"];
    [failedLabel setText:@"0"];
}

- (void)viewDidUnload
{
    [self setCompleteLabel:nil];
    [self setFailedLabel:nil];
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

- (IBAction)buttonPress:(id)sender {
    
    //Kick off several requests.  This will give the user time to turn
    //off the network connection and observe the results.
    
    //The client is setup for 1 conccurrent operation
    
    for(int i = 0; i < 30; i++){
        
    [[YWWeatherAPIClient sharedClient] 
     requestWeatherWithWOEID:arc4random()%30000
     success:^(AFHTTPRequestOperation *operation, id responseObject) {
         NSLog(@"Completed Request");
         [completeLabel setText:[NSString stringWithFormat:@"%d",++completedRequests_]];
     }
     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         NSLog(@"%@",error.localizedDescription);
         [failedLabel setText:[NSString stringWithFormat:@"%d",++failedRequests_]];
     }];
        
    }
}
- (void)dealloc {
    [completeLabel release];
    [failedLabel release];
    [super dealloc];
}
@end
