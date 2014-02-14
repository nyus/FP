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
- (IBAction)cancelButtonTapped:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *findButtonTapped;
@property (weak, nonatomic) IBOutlet UITextField *textField;

@end
