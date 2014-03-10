//
//  ViewMessageViewController.h
//  FastPost
//
//  Created by Huang, Jason on 2/26/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Message.h"
@interface ViewMessageViewController : UIViewController
@property (nonatomic, strong) Message *messageObject;
@property (weak, nonatomic) IBOutlet UITextView *messageTextView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *messageTextViewHeightContraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *enterMsgContainerViewBottomSpaceToBottomLayoutConstraint;
@property (weak, nonatomic) IBOutlet UITextView *enterMsgTextView;
@property (weak, nonatomic) IBOutlet UIView *enterMessageContainerView;
- (IBAction)replayButtonTapped:(id)sender;
- (IBAction)setTimeButtonTapped:(id)sender;
@end
