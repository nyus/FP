//
//  GenericReviveInputViewController.h
//  FastPost
//
//  Created by Huang, Jason on 8/18/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Message.h"
#import "Conversation.h"
#import "ExpirationTimePickerViewController.h"
@class ExpirationTimePickerViewController;

@interface GenericReviveInputViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,UITextViewDelegate,ExpirationTimePickerViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIView *enterMessageContainerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *enterMessageContainerViewBottomSpaceToBottomLayoutContraint;
@property (weak, nonatomic) IBOutlet UITextView *recipientsTextView;
@property (weak, nonatomic) IBOutlet UITextView *enterMessageTextView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
- (IBAction)sendButtonTapped:(id)sender;

@property (nonatomic) int expirationTimeInSec;
@property (nonatomic) BOOL isFromPushSegue;//composeNewMessageVC is modal and ViewAndSendMessageVC is push
@property (strong, nonatomic) ExpirationTimePickerViewController *expirationTimePickerVC;
@property (strong, nonatomic) NSMutableArray *contactArray;
@property (strong, nonatomic) NSMutableArray *filteredContactArray;
@property (strong, nonatomic) Conversation *conversation;
@property (strong, nonatomic) NSMutableArray *messageArray;
@property (strong, nonatomic) NSMutableArray *dataSource;
-(void)scrollTextViewToVisible:(UITextView *)textView;
@end
