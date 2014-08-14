//
//  ProfileViewController.h
//  FastPost
//
//  Created by Sihang Huang on 1/7/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewControllerWithStatusTableView.h"
@interface ProfileViewController : BaseViewControllerWithStatusTableView
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *dwindleLabel;
@property (weak, nonatomic) IBOutlet UILabel *followingLabel;
@property (weak, nonatomic) IBOutlet UILabel *followerLabel;
@property (weak, nonatomic) IBOutlet UIButton *followButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *followingTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *followersTitleLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *userNameLabelTopSpaceToTopLayoutConstraint;
@property (weak, nonatomic) IBOutlet UILabel *dwindleTitleLabel;
@property (strong,nonatomic) NSString *userNameOfUserProfileToDisplay;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@end
