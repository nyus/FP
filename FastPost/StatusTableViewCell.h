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
@optional
-(void)reviveStatusButtonTappedOnCell:(StatusTableViewCell *)cell;
-(void)usernameLabelTappedOnCell:(StatusTableViewCell *)cell;
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
@property (strong, nonatomic) NSIndexPath *indexPath;
-(void)resizeCellToFitStatusContent;
//-(void)setPlaceHolderImage;

//-(void)blurCell;
//-(void)unblurCell;
@end
