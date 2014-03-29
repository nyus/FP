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
-(void)reviveStatusButtonTappedOnCell:(StatusTableViewCell *)cell;
-(void)usernameLabelTappedOnCell:(StatusTableViewCell *)cell;
-(void)likeButtonTappedOnCell:(StatusTableViewCell *)cell;
-(void)commentButtonTappedOnCell:(StatusTableViewCell *)cell;
@end

@interface StatusTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *statusCellMessageLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusCellCountDownLabel;
@property (assign, nonatomic) id<StatusTableViewCellDelegate>delegate;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIImageView *statusCellPhotoImageView;
@property (weak, nonatomic) IBOutlet UILabel *statusCellUsernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusCellDateLabel;
@property (weak, nonatomic) IBOutlet UIImageView *statusCellAvatarImageView;
@property (weak, nonatomic) IBOutlet UIButton *statusCellReviveButton;
//cache calculated label height
@property (weak, nonatomic) NSMapTable *labelHeightMap;
//cache is there photo
@property (weak, nonatomic) NSMapTable *isTherePhotoMap;
//cache cell height
@property (weak, nonatomic) NSMapTable *cellHeightMap;
@property (strong,nonatomic) Status *status;

@property (strong, nonatomic) NSIndexPath *indexPath;
@property (weak, nonatomic) IBOutlet UIView *buttonsContainerView;
@property (weak, nonatomic) IBOutlet UIView *cellLineSeparator;
@property (weak, nonatomic) IBOutlet UILabel *likeCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *commentCountLabel;
//
@property (nonatomic, assign) BOOL needSocialButtons;

- (IBAction)likeButtonTapped:(id)sender;
- (IBAction)commentButtonTapped:(id)sender;
-(void)resizeCellToFitStatusContent;
//-(void)setPlaceHolderImage;

//-(void)blurCell;
//-(void)unblurCell;
@end
