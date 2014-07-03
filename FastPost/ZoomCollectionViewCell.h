//
//  ZoomCollectionViewCell.h
//  FastPost
//
//  Created by Sihang on 7/2/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZoomCollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIImageView *imageVIew;
-(void)showProgressIndicator;
-(void)hideProgressIndicator;
@end
