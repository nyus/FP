//
//  CommentStatusViewController.h
//  FastPost
//
//  Created by Sihang Huang on 3/12/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import <UIKit/UIKit.h>
@class StatusTableViewCell;
@interface CommentStatusViewController : UIViewController
@property (nonatomic, strong) NSString *statusObjectId;
@property (nonatomic) CGRect animateEndFrame;
@property (weak, nonatomic) StatusTableViewCell *statusTBCell;
-(void)clearCommentTableView;
@end
