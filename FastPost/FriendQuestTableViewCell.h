//
//  FriendQuestTableViewCell.h
//  FastPost
//
//  Created by Huang, Jason on 2/14/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FriendQuestTableViewCell;
@protocol FriendQuestTableViewCellDelegate <NSObject>

@optional
-(void)friendQuestTBCellAcceptButtonTappedWithCell:(FriendQuestTableViewCell *)self;
-(void)friendQuestTBCellNotNowButtonTappedWithCell:(FriendQuestTableViewCell *)self;

@end

@interface FriendQuestTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (assign,nonatomic) id<FriendQuestTableViewCellDelegate>delegate;
- (IBAction)acceptButtonTapped:(id)sender;
- (IBAction)notNowButtonTapped:(id)sender;

@end
