//
//  TestWindowController.h
//  AFNetworking Mac Example
//
//  Created by Darcy Laycock on 5/10/11.
//  Copyright 2011 Gowalla. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TestWindowController : NSWindowController {
    IBOutlet NSButton *requestButton;
    IBOutlet NSTextField *addressField;
    IBOutlet NSTextField *contentsField;
}

@property (retain) NSButton *requestButton;
@property (retain) NSTextField *addressField;
@property (retain) NSTextField *contentsField;

-(IBAction)requestWebPage:(id)sender;

@end
