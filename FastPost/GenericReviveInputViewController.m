//
//  GenericReviveInputViewController.m
//  FastPost
//
//  Created by Huang, Jason on 8/18/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "GenericReviveInputViewController.h"
#import <Parse/Parse.h>
#import "SharedDataManager.h"
@implementation GenericReviveInputViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

-(void)keyboardWillShow:(NSNotification *)sender{
    CGRect keyboardRect = [sender.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    [UIView animateWithDuration:[sender.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue] delay:0 options:[sender.userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue] animations:^{
        self.enterMessageContainerView.frame = CGRectMake(self.enterMessageContainerView.frame.origin.x,
                                                          keyboardRect.size.height,
                                                          self.enterMessageContainerView.frame.size.width,
                                                          self.enterMessageContainerView.frame.size.height);
        
    } completion:^(BOOL finished) {
        if(self.isFromPushSegue){
            self.enterMessageContainerViewBottomSpaceToBottomLayoutContraint.constant = keyboardRect.size.height-49;//minus tab bar
        }else{
            self.enterMessageContainerViewBottomSpaceToBottomLayoutContraint.constant = keyboardRect.size.height;
        }
        
    }];
}

-(void)keyboardWillHide:(NSNotification *)sender{
    
    CGRect keyboardRect = [sender.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    [UIView animateWithDuration:[sender.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue] delay:0 options:[sender.userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue] animations:^{
        self.enterMessageContainerView.frame = CGRectMake(self.enterMessageContainerView.frame.origin.x,
                                                          self.enterMessageContainerView.frame.origin.y + keyboardRect.size.height,
                                                          self.enterMessageContainerView.frame.size.width,
                                                          self.enterMessageContainerView.frame.size.height);
        
    } completion:^(BOOL finished) {
        self.enterMessageContainerViewBottomSpaceToBottomLayoutContraint.constant = 0;
    }];
}

- (IBAction)setTimeButtonTapped:(id)sender {
    
    [self.view endEditing:YES];
    
    //show picker
    //filter button typed
    if (!self.expirationTimePickerVC) {
        self.expirationTimePickerVC = [[ExpirationTimePickerViewController alloc] initWithNibName:@"ExpirationTimePickerViewController" bundle:nil type:PickerTypeRevive];
        self.expirationTimePickerVC.delegate = self;
        self.expirationTimePickerVC.view.frame = CGRectMake(0,
                                                       (self.view.frame.size.height - self.expirationTimePickerVC.view.frame.size.height)/2,
                                                       self.expirationTimePickerVC.view.frame.size.width,
                                                       self.expirationTimePickerVC.view.frame.size.height);
        self.expirationTimePickerVC.titleLabel.text = @"";
        
        UIToolbar *blurEffectToolBar = [[UIToolbar alloc] initWithFrame:self.expirationTimePickerVC.view.frame];
        blurEffectToolBar.barStyle = UIBarStyleDefault;
        //set a reference so that can remove it
        self.expirationTimePickerVC.blurToolBar = blurEffectToolBar;
        
        self.expirationTimePickerVC.view.alpha = 0.0f;
        self.expirationTimePickerVC.blurToolBar.alpha = 0.0f;
        [self.view.window addSubview:self.expirationTimePickerVC.view];
        [self.view.window insertSubview:blurEffectToolBar belowSubview:self.expirationTimePickerVC.view];
    }
    
    [UIView animateWithDuration:.3 animations:^{
        self.expirationTimePickerVC.view.alpha = 1.0f;
        self.expirationTimePickerVC.blurToolBar.alpha = 1.0f;
    }];
}

#pragma mark - ExpirationTimePickerViewControllerDelegate
-(void)revivePickerViewExpirationTimeSetToMins:(NSInteger)min andSecs:(NSInteger)sec andPickerView:(UIPickerView *)pickerView{
    //add time to status remotely
    self.expirationTimeInSec = (int)min * 60 + (int)sec;
}

-(void)scrollTextViewToVisible:(UITextView *)textView{
    
    [textView scrollRectToVisible:CGRectMake(0,
                                             textView.contentSize.height - 38,
                                             textView.frame.size.width,
                                             textView.frame.size.height)
                         animated:YES];
}

- (IBAction)sendButtonTapped:(id)sender {
    
    //do nothing is there is no recipient or no message
    if ([self.recipientsTextView.text isEqualToString:@""] || [self.enterMessageTextView.text isEqualToString:@""]) {
        return;
    }
    
    if (![self.enterMessageTextView isFirstResponder]) {
        return;
    }
    
    if (![self.contactArray containsObject:self.recipientsTextView.text]) {
        return;
    }
    
    //if this is a new conversation, create a new conversation object
    if (self.conversation == nil) {
        
        Conversation *conver = [NSEntityDescription insertNewObjectForEntityForName:@"Conversation" inManagedObjectContext:[SharedDataManager sharedInstance].managedObjectContext];
        conver.participants = [NSArray arrayWithObjects:self.recipientsTextView.text,[PFUser currentUser].username, nil];
        NSString *hashString = [conver.objectID.URIRepresentation.absoluteString stringByAppendingFormat:@"%@",[NSDate date]];
        conver.objectid = [NSString stringWithFormat:@"%d",hashString.hash];
        conver.lastUpdateDate = [NSDate date];
        
        self.conversation = conver;
        
        //save conversaton to parse
        PFObject *conversation = [PFObject objectWithClassName:@"Conversation"];
        conversation[@"participants"] = self.conversation.participants;
        conversation[@"objectid"] = self.conversation.objectid;
        conversation[@"lastUpdateDate"] = self.conversation.lastUpdateDate;
        [conversation saveEventually];
        
    }else{
        //update the value
        self.conversation.lastUpdateDate = [NSDate date];
        __block GenericReviveInputViewController *weakSelf = self;
        PFQuery *query = [PFQuery queryWithClassName:@"Conversation"];
        [query whereKey:@"objectid" equalTo:self.conversation.objectid];
        [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if (!error && object) {
                object[@"lastUpdateDate"] = weakSelf.conversation.lastUpdateDate;
                [object saveEventually];
            }
        }];
    }
    //update this value for conversation
    
    
    //create local message managedObject
    Message *localMsg = [NSEntityDescription insertNewObjectForEntityForName:@"Message" inManagedObjectContext:[SharedDataManager sharedInstance].managedObjectContext];
    localMsg.objectid = self.conversation.objectid;
    localMsg.content = self.enterMessageTextView.text;
    localMsg.senderUsername = [PFUser currentUser].username;
    localMsg.createdat = self.conversation.lastUpdateDate;
    if (self.expirationTimeInSec == 0) {
        //default to 10 mins
        self.expirationTimeInSec = 10*60;
    }
    localMsg.expirationDate = [NSDate dateWithTimeIntervalSinceNow:self.expirationTimeInSec];
    //reset
    self.expirationTimeInSec = 0;
    localMsg.participants = self.conversation.participants;
    //
    self.conversation.lastMessageContent = localMsg.content;
    [[SharedDataManager sharedInstance] saveContext];
    
    if (!self.messageArray) {
        self.messageArray = [NSMutableArray array];
    }
    [self.messageArray addObject:localMsg];
    
    //reload tbview
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.messageArray.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
    //scroll to visible
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.messageArray.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    //clear out textfield
    self.enterMessageTextView.text = nil;
    
    //save message to parse
    PFObject *message = [PFObject objectWithClassName:@"Message"];
    message[@"objectid"] = localMsg.objectid;
    message[@"content"] = localMsg.content;
    message[@"senderUsername"] = localMsg.senderUsername;
    message[@"expirationDate"] = localMsg.expirationDate;
    message[@"participants"] = localMsg.participants;
    [message saveEventually];
    
    //push notification
    for (NSString *recipient in localMsg.participants) {
        if ([recipient isEqualToString:[PFUser currentUser].username]) {
            continue;
        }
        //first query the PFUser(recipient) with the specific username
        PFQuery *innerQuery = [PFQuery queryWithClassName:[PFUser parseClassName]];
        [innerQuery whereKey:@"username" equalTo:recipient];
        //then query this PFuser set on PFInstallation
        PFQuery *query = [PFInstallation query];
        [query whereKey:@"user" matchesQuery:innerQuery];
        
        PFPush *push = [[PFPush alloc] init];
        [push setQuery:query];
        [push setMessage:[NSString stringWithFormat:@"%@ has sent you a new message",recipient]];
        [push sendPushInBackground];
    }
}

@end
