//
//  AFImageResponseSerializerTests.m
//  AFNetworking Tests
//
//  Created by Plunien, Johannes on 17/12/14.
//  Copyright (c) 2014 AFNetworking. All rights reserved.
//

#import "AFTestCase.h"

#import "AFURLResponseSerialization.h"

@interface AFImageResponseSerializerTests : AFTestCase
@property (readwrite, nonatomic, strong) AFImageResponseSerializer *responseSerializer;
@property (readwrite, nonatomic, strong) NSURLSession *session;
@end

@implementation AFImageResponseSerializerTests

- (void)setUp {
    [super setUp];

    self.responseSerializer = [AFImageResponseSerializer serializer];
    self.responseSerializer.imageScale = 1.0f;
    self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
}

- (void)testImageResponseSerializer {
    NSMutableArray *images = [NSMutableArray array];
    for (int i=0; i<20; i++) {
        NSURL *url = [NSURL URLWithString:@"http://i.ebayimg.com/00/s/NzY4WDEwMjQ=/z/OoIAAOSwAL9UkVnH/$_93.JPG"];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            UIImage *image = [self.responseSerializer responseObjectForResponse:response data:data error:nil];
            [images addObject:image];
        }];
        [task resume];
    }
    expect(images.count).will.equal(20);

    // Now I'd expect all images to be the same, but they are not. Add a break point here and check
    // the images with quicklook and see yourself. Some of them are broken.
    for (UIImage *image1 in images) {
        for (UIImage *image2 in images) {
            NSData *data1 = UIImagePNGRepresentation(image1);
            NSData *data2 = UIImagePNGRepresentation(image2);
            XCTAssertTrue([data1 isEqual:data2]);
        }
    }
}

@end
