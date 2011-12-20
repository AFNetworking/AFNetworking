//
//  AFViewController.h
//  AFReachableExample
//
//  Created by Kevin Harwood on 12/20/11.
//  Copyright (c) 2011 Mutual Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AFViewController : UIViewController

@property (retain, nonatomic) IBOutlet UILabel *completeLabel;
@property (retain, nonatomic) IBOutlet UILabel *failedLabel;

- (IBAction)buttonPress:(id)sender;

@end
