//
//  ComposeNewMessageViewController.h
//  FastPost
//
//  Created by Sihang Huang on 2/9/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Conversation;
@interface ComposeNewMessageViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITableView *tableView;
- (IBAction)cancelButtonTapped:(id)sender;

- (IBAction)sendButtonTapped:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *showContactButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *recipientsTextViewHeightContraint;
@property (weak, nonatomic) IBOutlet UIButton *reviveButton;
@property (weak, nonatomic) IBOutlet UITextView *recipientsTextView;
@property (weak, nonatomic) IBOutlet UITextView *enterMessageTextView;
@property (weak, nonatomic) IBOutlet UIView *enterMessageContainerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *enterMessageContainerViewBottomSpaceToBottomLayoutContraint;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *recipientContainerViewHeightConstraint;
@property (weak, nonatomic) IBOutlet UIView *recipientContainerView;
@property (nonatomic, strong) Conversation *conversation;
- (IBAction)setTimeButtonTapped:(id)sender;
@end
