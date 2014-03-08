//
//  ComposeNewMessageViewController.h
//  FastPost
//
//  Created by Sihang Huang on 2/9/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ComposeNewMessageViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITableView *tableView;
- (IBAction)cancelButtonTapped:(id)sender;

- (IBAction)sendButtonTapped:(id)sender;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *recipientsTextViewHeightContraint;
@property (weak, nonatomic) IBOutlet UITextView *recipientsTextView;
@property (weak, nonatomic) IBOutlet UITextView *enterMessageTextView;
@property (weak, nonatomic) IBOutlet UIView *enterMessageContainerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *enterMessageContainerViewBottomSpaceToBottomLayoutContraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *recipientContainerViewHeightConstraint;
@property (weak, nonatomic) IBOutlet UIView *recipientContainerView;
@property (weak, nonatomic) IBOutlet UITextView *textView;
- (IBAction)setTimeButtonTapped:(id)sender;
@end
