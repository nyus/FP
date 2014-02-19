//
//  FriendQuestViewController.h
//  FastPost
//
//  Created by Huang, Jason on 2/14/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FriendQuestViewController : UIViewController
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UITextField *textField;

@property (nonatomic) BOOL isOnScreen;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (strong, nonatomic) UIToolbar *blurToolBar;
-(void)removeSelfFromParent;
@end
