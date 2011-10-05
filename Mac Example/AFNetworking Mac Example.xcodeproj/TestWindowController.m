//
//  TestWindowController.m
//  AFNetworking Mac Example
//
//  Created by Darcy Laycock on 5/10/11.
//  Copyright 2011 Gowalla. All rights reserved.
//

#import "TestWindowController.h"
#import "AFHTTPRequestOperation.h"

@implementation TestWindowController

@synthesize requestButton, addressField, contentsField;

-(IBAction)requestWebPage:(id)sender
{
    NSURL *url = [NSURL URLWithString:addressField.stringValue];
    requestButton.enabled = false;
    contentsField.stringValue = @"";
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFHTTPRequestOperation *operation = [AFHTTPRequestOperation operationWithRequest:request completion:^(NSURLRequest *request, NSHTTPURLResponse *response, NSData *data, NSError *error) {
        // Check response.
        if(error) {
            [[NSAlert alertWithError:error] runModal];
        } else {
            NSLog(@"Response = %@", response);
            NSString *responseData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            contentsField.stringValue = responseData;
            [responseData release];
        }
        requestButton.enabled = true;
    }];
    NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
    [queue addOperation:operation];
}

@end
