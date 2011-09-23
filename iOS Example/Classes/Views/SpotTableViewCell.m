// SpotTableViewCell.m
//
// Copyright (c) 2011 Gowalla (http://gowalla.com/)
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

#import "SpotTableViewCell.h"

#import "Spot.h"

#import "UIImageView+AFNetworking.h"

@implementation SpotTableViewCell
@synthesize spot = _spot;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (!self) {
        return nil; 
    }
    
    self.textLabel.textColor = [UIColor darkGrayColor];
    self.textLabel.numberOfLines = 2;
    self.textLabel.backgroundColor = self.backgroundColor;
    
    self.detailTextLabel.textColor = [UIColor grayColor];
    self.detailTextLabel.backgroundColor = self.backgroundColor;

    self.imageView.backgroundColor = self.backgroundColor;
    
    self.selectionStyle = UITableViewCellSelectionStyleGray;
    
    return self;
}

- (void)dealloc {
    [_spot release];
    [super dealloc];
}

- (void)setSpot:(Spot *)spot {
    [self willChangeValueForKey:@"spot"];
    [_spot autorelease];
    _spot = [spot retain];
    [self didChangeValueForKey:@"spot"];

    [self.imageView setImageWithURL:[NSURL URLWithString:self.spot.imageURLString] placeholderImage:[UIImage imageNamed:@"placeholder-stamp.png"]];
     
    self.textLabel.text = spot.name;
}

#pragma mark - UITableViewCell

- (void)prepareForReuse {
    [self.imageView cancelImageRequestOperation];
    self.textLabel.text = nil;
    self.detailTextLabel.text = nil;
}

@end
