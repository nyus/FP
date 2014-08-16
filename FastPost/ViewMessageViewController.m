//
//  ViewMessageViewController.m
//  FastPost
//
//  Created by Huang, Sihang on 2/26/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "ViewMessageViewController.h"
#import <Parse/Parse.h>
#import "SharedDataManager.h"
#import "ExpirationTimePickerViewController.h"
@interface ViewMessageViewController ()<ExpirationTimePickerViewControllerDelegate,UITextViewDelegate>{
    ExpirationTimePickerViewController *expirationTimePickerVC;
    int expirationTimeInSec;
}

@end

@implementation ViewMessageViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    
	// Do any additional setup after loading the view.
    self.messageTextView.text = self.messageObject.content;
    self.messageTextView.delegate = self;
    
    //bring up keyboard
    [self.enterMsgTextView becomeFirstResponder];
    
    
    if (self.messageObject.read.boolValue != YES) {
        //update read property in core data
        self.messageObject.read = [NSNumber numberWithBool:YES];
        [[SharedDataManager sharedInstance] saveContext];
        
        //update read property on the server
        PFQuery *query = [[PFQuery alloc] initWithClassName:@"Message"];
        [query whereKey:@"objectId" equalTo:self.messageObject.objectid];
        [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if (!error && object) {
                object[@"read"] = [NSNumber numberWithBool:YES];
                [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (!succeeded) {
                        NSLog(@"set message %@ status to read",object);
                    }
                }];
            }
        }];
    }
}

-(void)keyboardWillShow:(NSNotification *)sender{
    CGRect keyboardRect = [sender.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    
    [UIView animateWithDuration:[sender.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue] delay:0 options:[sender.userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue] animations:^{
        self.enterMessageContainerView.frame = CGRectMake(self.enterMessageContainerView.frame.origin.x,
                                                          self.enterMessageContainerView.frame.origin.y - keyboardRect.size.height + self.bottomLayoutGuide.length,
                                                          self.enterMessageContainerView.frame.size.width,
                                                          self.enterMessageContainerView.frame.size.height);
        
    } completion:^(BOOL finished) {
        self.enterMsgContainerViewBottomSpaceToBottomLayoutConstraint.constant = keyboardRect.size.height - self.bottomLayoutGuide.length;
    }];
    
    
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)replayButtonTapped:(id)sender {
    
    //do nothing is there is no recipient or no message
    if ([self.enterMsgTextView.text isEqualToString:@""]) {
        return;
    }
    
    PFObject *message = [PFObject objectWithClassName:@"Message"];
    message[@"senderUsername"] = [PFUser currentUser].username;
    //we are replying this sender
    message[@"receiverUsername"]= self.messageObject.senderUsername;
    message[@"message"] = self.messageTextView.text;

    if (expirationTimeInSec == 0) {
        //default to 10 mins
        expirationTimeInSec = 10*60;
    }

    message[@"expirationTimeInSec"] = [NSNumber numberWithInt:expirationTimeInSec];
    message[@"expirationDate"] = [NSDate dateWithTimeIntervalSinceNow:expirationTimeInSec];
    message[@"read"] = [NSNumber numberWithBool:NO];
    //reset
    expirationTimeInSec = 0;
    
    [message saveInBackground];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)setTimeButtonTapped:(id)sender {

    self.enterMsgContainerViewBottomSpaceToBottomLayoutConstraint.constant = 0;
    
    [self.view endEditing:YES];
    
    //show picker
    //filter button typed
    if (!expirationTimePickerVC) {
        expirationTimePickerVC = [[ExpirationTimePickerViewController alloc] initWithNibName:@"ExpirationTimePickerViewController" bundle:nil type:PickerTypeRevive];
        expirationTimePickerVC.delegate = self;
        expirationTimePickerVC.view.frame = CGRectMake(0,
                                                       (self.view.frame.size.height - expirationTimePickerVC.view.frame.size.height)/2,
                                                       expirationTimePickerVC.view.frame.size.width,
                                                       expirationTimePickerVC.view.frame.size.height);
        expirationTimePickerVC.titleLabel.text = @"";
        
        UIToolbar *blurEffectToolBar = [[UIToolbar alloc] initWithFrame:expirationTimePickerVC.view.frame];
        blurEffectToolBar.barStyle = UIBarStyleDefault;
        //set a reference so that can remove it
        expirationTimePickerVC.blurToolBar = blurEffectToolBar;
        
        expirationTimePickerVC.view.alpha = 0.0f;
        expirationTimePickerVC.blurToolBar.alpha = 0.0f;
        [self.view.window addSubview:expirationTimePickerVC.view];
        [self.view.window insertSubview:blurEffectToolBar belowSubview:expirationTimePickerVC.view];
    }
    
    [UIView animateWithDuration:.3 animations:^{
        expirationTimePickerVC.view.alpha = 1.0f;
        expirationTimePickerVC.blurToolBar.alpha = 1.0f;
    }];
}

#pragma mark - ExpirationTimePickerViewControllerDelegate
-(void)revivePickerViewExpirationTimeSetToMins:(NSInteger)min andSecs:(NSInteger)sec andPickerView:(UIPickerView *)pickerView{
    //add time to status remotely
    expirationTimeInSec = (int)min * 60 + (int)sec;
}

#pragma mark - UITextView

-(void)textViewDidChange:(UITextView *)textView{
    //    [textView scrollRangeToVisible:textRange];
    [self performSelector:@selector(scrollTextViewToVisible) withObject:nil afterDelay:0.1];
    
}

-(void)scrollTextViewToVisible{
    [self.messageTextView scrollRectToVisible:CGRectMake(0,
                                                         self.messageTextView.contentSize.height - 38,
                                                         self.messageTextView.frame.size.width,
                                                         self.messageTextView.frame.size.height)
                                     animated:YES];
}

-(void)textViewDidBeginEditing:(UITextView *)textView{
    [UIView animateWithDuration:.3 animations:^{
        expirationTimePickerVC.view.alpha = 0.0f;
        expirationTimePickerVC.blurToolBar.alpha = 0.0f;
    }];
}
@end
