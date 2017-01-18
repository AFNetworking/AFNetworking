//
//  DetailViewController.h
//  AFNetworkingXMLRPCExample
//
//  Created by Jorge Bernal on 10/8/11.
//  Copyright (c) 2011 Automattic. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) NSDictionary *detailItem;

@property (strong, nonatomic) IBOutlet UIWebView *contentWebView;
@property (strong, nonatomic) IBOutlet UIImageView *gravatarView;
@property (strong, nonatomic) IBOutlet UILabel *authorLabel;
@property (strong, nonatomic) IBOutlet UILabel *emailLabel;

@end

NSString *md5(NSString *str);