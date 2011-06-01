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

@implementation SpotTableViewCell
@synthesize imageURLString = _imageURLString;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (!self) {
        return nil; 
    }
    
    self.textLabel.textColor = [UIColor darkGrayColor];
    self.textLabel.numberOfLines = 2;
    
    self.detailTextLabel.textColor = [UIColor grayColor];
    
    self.selectionStyle = UITableViewCellSelectionStyleGray;
    
    return self;
}

- (void)dealloc {
    [_imageURLString release];
    [super dealloc];
}

- (void)setImageURLString:(NSString *)imageURLString {
    [self setImageURLString:imageURLString options:AFImageRequestResize | AFImageCacheProcessedImage];
}

- (void)setImageURLString:(NSString *)imageURLString options:(AFImageRequestOptions)options {
	if ([self.imageURLString isEqual:imageURLString]) {
		return;
	}
    
	if (self.imageURLString) {
		self.imageView.image = [UIImage imageNamed:@"placeholder-stamp.png"];
	}
	
	[self willChangeValueForKey:@"imageURLString"];
	[_imageURLString release];
	_imageURLString = [imageURLString copy];
	[self didChangeValueForKey:@"imageURLString"];
	
	if (self.imageURLString) {
		[AFImageRequest requestImageWithURLString:self.imageURLString size:CGSizeMake(50.0f, 50.0f) options:options block:^(UIImage *image) {
			if ([self.imageURLString isEqualToString:imageURLString]) {
				BOOL needsLayout = self.imageView.image == nil;
                self.imageView.image = image;
				
				if (needsLayout) {
					[self setNeedsLayout];
				}
            }
		}];
	}
}

#pragma mark - UITableViewCell

- (void)prepareForReuse {
    [super prepareForReuse];
    [AFImageRequest cancelImageRequestOperationsForURLString:self.imageURLString];
}

#pragma mark - UIView

- (void)layoutSubviews {
	[super layoutSubviews];
	
	CGRect imageViewFrame = self.imageView.frame;
	CGRect textLabelFrame = self.textLabel.frame;
	CGRect detailTextLabelFrame = self.detailTextLabel.frame;
	
	imageViewFrame.origin = CGPointMake(10.0f, 10.0f);
	imageViewFrame.size = CGSizeMake(50.0f, 50.0f);
             
	textLabelFrame.origin.x = imageViewFrame.size.width + 30.0f;
    detailTextLabelFrame.origin.x = textLabelFrame.origin.x;
	
    textLabelFrame.size.width = 240.0f;
	detailTextLabelFrame.size.width = textLabelFrame.size.width;
	
	self.textLabel.frame = textLabelFrame;
	self.detailTextLabel.frame = detailTextLabelFrame;
	self.imageView.frame = imageViewFrame;
}

@end
