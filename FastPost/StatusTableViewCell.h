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
@class SpinnerImageView;
@protocol StatusTableViewCellDelegate <NSObject>
@optional
-(void)usernameLabelTappedOnCell:(StatusTableViewCell *)cell;
-(void)commentButtonTappedOnCell:(StatusTableViewCell *)cell;
-(void)reviveAnimationDidEndOnCell:(StatusTableViewCell *)cell withProgress:(float)percentage;
-(void)swipeGestureRecognizedOnCell:(StatusTableViewCell *)cell;
@end

@interface StatusTableViewCell : UITableViewCell<UICollectionViewDataSource>{
}
@property (strong,nonatomic) Status *status;
@property (assign, nonatomic) id<StatusTableViewCellDelegate>delegate;
@property (weak, nonatomic) IBOutlet UILabel *statusCellMessageLabel;
@property (weak, nonatomic) IBOutlet SpinnerImageView *statusCellPhotoImageView;
@property (weak, nonatomic) IBOutlet UILabel *statusCellUsernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusCellDateLabel;
@property (weak, nonatomic) IBOutlet UIImageView *statusCellAvatarImageView;
@property (weak, nonatomic) IBOutlet UIView *reviveProgressView;
@property (weak, nonatomic) IBOutlet UILabel *reviveCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *commentCountLabel;
@property (weak, nonatomic) IBOutlet UIButton *userNameButton;
@property (weak, nonatomic) IBOutlet UIButton *commentButton;
@property (weak, nonatomic) IBOutlet UIButton *avatarButton;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIView *contentContainerView;
@property (strong, nonatomic) NSMutableArray *collectionViewImagesArray;
-(void)disableRevivePressHoldGesture;
-(void)enableRevivePressHoldGesture;
- (IBAction)commentButtonTapped:(id)sender;

@end
