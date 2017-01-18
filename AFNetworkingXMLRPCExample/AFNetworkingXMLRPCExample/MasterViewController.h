//
//  MasterViewController.h
//  AFNetworkingXMLRPCExample
//
//  Created by Jorge Bernal on 10/8/11.
//  Copyright (c) 2011 Automattic. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DetailViewController;

@interface MasterViewController : UITableViewController

@property (strong, nonatomic) DetailViewController *detailViewController;
@property (strong) NSMutableArray *comments;

@end
