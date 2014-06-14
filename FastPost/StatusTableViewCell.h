//
//  StatusTableCell.h
//  FastPost
//
//  Created by Huang, Sihang on 11/25/13.
//  Copyright (c) 2013 Huang, Sihang. All rights reserved.
//

#import <UIKit/UIKit.h>

@class StatusTableViewCell;
@class Status;
@protocol StatusTableViewCellDelegate <NSObject>
@optional
-(void)usernameLabelTappedOnCell:(StatusTableViewCell *)cell;
-(void)likeButtonTappedOnCell:(StatusTableViewCell *)cell;
-(void)commentButtonTappedOnCell:(StatusTableViewCell *)cell;
-(void)reviveAnimationDidEndOnCell:(StatusTableViewCell *)cell withProgress:(float)percentage;
@end

@interface StatusTableViewCell : UITableViewCell
@property (strong,nonatomic) Status *status;
@property (assign, nonatomic) id<StatusTableViewCellDelegate>delegate;
@property (weak, nonatomic) IBOutlet UILabel *statusCellMessageLabel;
@property (weak, nonatomic) IBOutlet UIImageView *statusCellPhotoImageView;
@property (weak, nonatomic) IBOutlet UILabel *statusCellUsernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusCellDateLabel;
@property (weak, nonatomic) IBOutlet UIImageView *statusCellAvatarImageView;
@property (weak, nonatomic) IBOutlet UIView *reviveProgressView;
@property (weak, nonatomic) IBOutlet UILabel *reviveCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *commentCountLabel;
@property (weak, nonatomic) IBOutlet UIButton *userNameButton;

-(void)disableRevivePressHoldGesture;
-(void)enableRevivePressHoldGesture;
- (IBAction)likeButtonTapped:(id)sender;
- (IBAction)commentButtonTapped:(id)sender;

@end
