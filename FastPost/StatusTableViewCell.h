//
//  StatusTableCell.h
//  FastPost
//
//  Created by Huang, Jason on 11/25/13.
//  Copyright (c) 2013 Huang, Jason. All rights reserved.
//

#import <UIKit/UIKit.h>

@class StatusTableViewCell;
@protocol StatusTableViewCellDelegate <NSObject>
-(void)reviveStatusButtonTappedOnCell:(StatusTableViewCell *)cell;
@end

@interface StatusTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UILabel *countDownLabel;
@property (assign, nonatomic) id<StatusTableViewCellDelegate>delegate;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIImageView *pictureImageView;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;

-(void)resizeCellToFitStatusContent;
//-(void)setPlaceHolderImage;

//-(void)blurCell;
//-(void)unblurCell;
@end
