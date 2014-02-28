//
//  MessageTableViewCell.h
//  FastPost
//
//  Created by Sihang Huang on 2/9/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MessageTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *msgCellProfileImageView;
@property (weak, nonatomic) IBOutlet UILabel *msgCellUsernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *msgCellCountDownLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

@end
