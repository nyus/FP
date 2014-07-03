//
//  ZoomCollectionViewCell.m
//  FastPost
//
//  Created by Sihang on 7/2/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "ZoomCollectionViewCell.h"

@interface ZoomCollectionViewCell()<UIScrollViewDelegate>

@end

@implementation ZoomCollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)awakeFromNib{
    self.scrollView.minimumZoomScale = 1.0f;
    self.scrollView.maximumZoomScale = 3.0f;
    self.scrollView.delegate = self;
}

-(void)showProgressIndicator{
    self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];
}


-(void)hideProgressIndicator{
    [self.activityIndicator stopAnimating];
    self.activityIndicator.hidden = YES;
}

#pragma mark - uiscrollview

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return self.imageVIew;
}

@end
