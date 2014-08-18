//
//  ComposeNewMessageViewController.m
//  FastPost
//
//  Created by Sihang Huang on 2/9/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "ComposeNewMessageViewController.h"
#import <Parse/Parse.h>
#import "Helper.h"
#import "ExpirationTimePickerViewController.h"
#import "AvatarAndUsernameTableViewCell.h"
#import "Conversation.h"
#import "Message.h"
#import "SharedDataManager.h"
#import "MessageTableViewViewController.h"
static const int FETCH_COUNT = 10;
@interface ComposeNewMessageViewController ()<UITableViewDataSource,UITableViewDelegate,UITextViewDelegate,ExpirationTimePickerViewControllerDelegate>{
    ExpirationTimePickerViewController *expirationTimePickerVC;
    int expirationTimeInSec;
    NSRange textRange;
    NSMutableArray *contactArray;
    NSMutableArray *filteredContactArray;
    BOOL messageMode;
    NSMutableArray *messageArray;
}
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation ComposeNewMessageViewController

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
	// Do any additional setup after loading the view.
    //register for keyboard notification
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [self createTimer];
    
    [self.recipientsTextView becomeFirstResponder];
    self.reviveButton.hidden = YES;
    self.sendButton.enabled = NO;
    
    contactArray = [NSMutableArray array];
    filteredContactArray = [NSMutableArray array];
    //skip current user's username
    //need to pull self.friends
    dispatch_queue_t queue = dispatch_queue_create("refreshUser", NULL);
    dispatch_async(queue, ^{
        [[PFUser currentUser] refresh];
        for (NSString *username in [[PFUser currentUser] objectForKey:UsersICanMessage]) {
            if([username isEqualToString:[PFUser currentUser].username]){
                continue;
            }
            [contactArray addObject:username];
        }
        
        //sort dataSource alphabetically
        [contactArray sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        
        for (NSString *username in contactArray) {
            [filteredContactArray addObject:username];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (filteredContactArray.count == 0) {
                self.showContactButton.enabled = NO;
            }
            
            [self.tableView reloadData];
        });
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self destroyTimer];
}

-(void)createTimer{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(handletimerFired:) userInfo:nil repeats:YES];
}

-(void)destroyTimer{
    [self.timer invalidate];
    self.timer = nil;
}

-(void)handletimerFired:(NSTimer *)timer{
    //here fetch from parse
}

-(void)fetchMessageWithCount:(int)count andOffset:(int)offset{
    
}

-(void)keyboardWillShow:(NSNotification *)sender{
    CGRect keyboardRect = [sender.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];

    [UIView animateWithDuration:[sender.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue] delay:0 options:[sender.userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue] animations:^{
        self.enterMessageContainerView.frame = CGRectMake(self.enterMessageContainerView.frame.origin.x,
                                                          keyboardRect.size.height,
                                                          self.enterMessageContainerView.frame.size.width,
                                                          self.enterMessageContainerView.frame.size.height);

    } completion:^(BOOL finished) {
        self.enterMessageContainerViewBottomSpaceToBottomLayoutContraint.constant = keyboardRect.size.height;
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

#pragma mark - UITableView

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    if (messageMode) {
        //+1 is the loading cell
        if(messageArray.count <FETCH_COUNT){
            //everytime we fetch, we fetch 10 messages, if messageArray.count < 10, then there is no more message to load. no need to add the loading cel
            return messageArray.count;
        }else{
            //
            return messageArray.count+1;
        }
        
    }else if (contactArray.count == 0 || (contactArray.count!=0 && filteredContactArray.count == 0)) {
        //no contact cell
        return 1;
    }else{
        return filteredContactArray.count;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *contactCell = @"contactCell";
    static NSString *messageCell = @"messageCell";
    static NSString *noContactCell = @"noContactCell";
    static NSString *noResultCell = @"noResultCell";
    static NSString *loadingCell = @"loadingCell";
    
    if (messageMode == NO) {
        
        if (contactArray.count == 0) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:noContactCell forIndexPath:indexPath];
            return cell;
        }else if(filteredContactArray.count == 0){
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:noResultCell forIndexPath:indexPath];
            return cell;
        }else{
            __block AvatarAndUsernameTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:contactCell forIndexPath:indexPath];
            
            //username
            cell.usernameLabel.text = filteredContactArray[indexPath.row];
            //profile picture
            [Helper getAvatarForUser:filteredContactArray[indexPath.row] avatarType:AvatarTypeMid isHighRes:NO completion:^(NSError *error, UIImage *image) {
                cell.avatarImageView.image = image;
            }];
            
            return cell;
        }
        
    }else{
        
        if(messageArray.count <FETCH_COUNT){
            //everytime we fetch, we fetch 10 messages, if messageArray.count < 10, then there is no more message to load. no need to add the loading cel
            id cell = [tableView dequeueReusableCellWithIdentifier:messageCell forIndexPath:indexPath];
            return cell;
        }else{
            if (indexPath.row == 0) {
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:loadingCell forIndexPath:indexPath];
                return cell;
            }else{
                id cell = [tableView dequeueReusableCellWithIdentifier:messageCell forIndexPath:indexPath];
                return cell;
            }
        }
    }
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if ([cell.reuseIdentifier isEqualToString:@"loadingCell"]) {
        
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if ([cell isKindOfClass:[AvatarAndUsernameTableViewCell class]]) {
        AvatarAndUsernameTableViewCell *contact = (AvatarAndUsernameTableViewCell *)cell;
        self.recipientsTextView.text = contact.usernameLabel.text;
        messageMode = YES;
        [self fetchMessageWithCount:FETCH_COUNT andOffset:0];
        [self.tableView reloadData];
        [self.enterMessageTextView becomeFirstResponder];
        self.reviveButton.hidden = NO;
        self.sendButton.enabled = YES;
    }
//    if ([self.recipientsTextView.text isEqualToString:@""]) {
//        self.recipientsTextView.text = cell.textLabel.text;
//        self.recipientsTextView.font = [UIFont systemFontOfSize:19];
//        self.recipientsTextView.textColor = [UIColor colorWithRed:0.0f green:122.0/255.0 blue:255.0/255.0 alpha:1];
//    }else if ([self.recipientsTextView.text rangeOfString:cell.textLabel.text].location == NSNotFound) {
//        //dont allow the same recipient from appearing more than one time
//        self.recipientsTextView.text = [self.recipientsTextView.text stringByAppendingFormat:@", %@",cell.textLabel.text];
//        self.recipientsTextView.font = [UIFont systemFontOfSize:19];
//        self.recipientsTextView.textColor = [UIColor colorWithRed:0.0f green:122.0/255.0 blue:255.0/255.0 alpha:1];
//        
//    }
    
    //reason for the delay is, ios is calculating the new content size after the text gets changed. if there is no delay, wont get the accurate content size
//    [self performSelector:@selector(adjustRecipientFieldHeight) withObject:nil afterDelay:0.01];
    //cancel highlight
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)adjustRecipientFieldHeight{
    //adjust height as number of recipients grow.
    if (self.recipientsTextView.contentSize.height > self.recipientContainerView.frame.size.height) {
        self.recipientContainerViewHeightConstraint.constant = self.recipientsTextView.contentSize.height;
    }
}

-(void)filterContacts{
    
    if ([self.recipientsTextView.text isEqualToString:@""]) {
        filteredContactArray = [contactArray mutableCopy];
    }else{
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@",self.recipientsTextView.text];
        NSArray *array = [contactArray filteredArrayUsingPredicate:predicate];
        filteredContactArray = nil;
        filteredContactArray = [array mutableCopy];
    }
    [self.tableView reloadData];
}

#pragma mark - UITextView

-(void)textViewDidChange:(UITextView *)textView{
    
    if (textView==self.enterMessageTextView) {
        [self performSelector:@selector(scrollTextViewToVisible) withObject:nil afterDelay:0.1];
    }else if (textView == self.recipientsTextView){
        self.sendButton.enabled = NO;
        messageMode = NO;
        [self filterContacts];
    }
}

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    return YES;
}

-(void)scrollTextViewToVisible{
    [self.enterMessageTextView scrollRectToVisible:CGRectMake(0,
                                                  self.enterMessageTextView.contentSize.height - 38,
                                                  self.enterMessageTextView.frame.size.width,
                                                  self.enterMessageTextView.frame.size.height)
                              animated:YES];
}

-(void)textViewDidBeginEditing:(UITextView *)textView{
    [UIView animateWithDuration:.3 animations:^{
        expirationTimePickerVC.view.alpha = 0.0f;
        expirationTimePickerVC.blurToolBar.alpha = 0.0f;
    }];
}

- (IBAction)cancelButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)sendButtonTapped:(id)sender {
    
    //do nothing is there is no recipient or no message
    if ([self.recipientsTextView.text isEqualToString:@""] || [self.enterMessageTextView.text isEqualToString:@""]) {
        return;
    }
    
    if (![self.enterMessageTextView isFirstResponder]) {
        return;
    }
    
    if (![contactArray containsObject:self.recipientsTextView.text]) {
        return;
    }
    
    //if this is a new conversation, create a new conversation object
    if (self.conversation == nil) {
        
        Conversation *conver = [NSEntityDescription insertNewObjectForEntityForName:@"Conversation" inManagedObjectContext:[SharedDataManager sharedInstance].managedObjectContext];
        conver.participants = [NSArray arrayWithObjects:self.recipientsTextView.text,[PFUser currentUser].username, nil];
        conver.objectid = [NSString stringWithFormat:@"%d",conver.objectID.URIRepresentation.absoluteString.hash];
        self.conversation = conver;
    }
    //update this value for conversation
    self.conversation.lastUpdateDate = [NSDate date];
    
    //save conversaton to parse
    PFObject *conversation = [PFObject objectWithClassName:@"Conversation"];
    conversation[@"participants"] = self.conversation.participants;
    conversation[@"objectid"] = self.conversation.objectid;
    conversation[@"lastUpdateDate"] = self.conversation.lastUpdateDate;
    [conversation saveEventually];
    
    //create local message managedObject
    Message *localMsg = [NSEntityDescription insertNewObjectForEntityForName:@"Message" inManagedObjectContext:[SharedDataManager sharedInstance].managedObjectContext];
    localMsg.objectid = self.conversation.objectid;
    localMsg.content = self.enterMessageTextView.text;
    localMsg.senderUsername = [PFUser currentUser].username;
    localMsg.createdAt = self.conversation.lastUpdateDate;
    if (expirationTimeInSec == 0) {
        //default to 10 mins
        expirationTimeInSec = 10*60;
    }
    localMsg.expirationDate = [NSDate dateWithTimeIntervalSinceNow:expirationTimeInSec];
    //reset
    expirationTimeInSec = 0;
    localMsg.participants = self.conversation.participants;
    [[SharedDataManager sharedInstance] saveContext];
    
    if (!messageArray) {
        messageArray = [NSMutableArray array];
    }
    [messageArray addObject:localMsg];
    
    //reload tbview
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:messageArray.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:messageArray.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
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
    
    
    
//    NSString *recipientString = [self.recipientsTextView.text stringByReplacingOccurrencesOfString:@" " withString:@""];
//    NSArray *recipients = [recipientString componentsSeparatedByString:@","];
//    for (NSString *recipient in recipients) {
//        PFObject *message = [PFObject objectWithClassName:@"Message"];
//        message[@"senderUsername"] = [PFUser currentUser].username;
//        message[@"receiverUsername"]= recipient;
//        message[@"message"] = self.enterMessageTextView.text;
//        
//        if (expirationTimeInSec == 0) {
//            //default to 10 mins
//            expirationTimeInSec = 10*60;
//        }
//        
//        message[@"expirationTimeInSec"] = [NSNumber numberWithInt:expirationTimeInSec];
//        message[@"expirationDate"] = [NSDate dateWithTimeIntervalSinceNow:expirationTimeInSec];
//        message[@"read"] = [NSNumber numberWithBool:NO];
//        //reset
//        expirationTimeInSec = 0;
//        
//        [message saveInBackground];
//        
//        //first query the PFUser(recipient) with the specific username
//        PFQuery *innerQuery = [PFQuery queryWithClassName:[PFUser parseClassName]];
//        [innerQuery whereKey:@"username" equalTo:recipient];
//        //then query this PFuser set on PFInstallation
//        PFQuery *query = [PFInstallation query];
//        [query whereKey:@"user" matchesQuery:innerQuery];
//        
//        PFPush *push = [[PFPush alloc] init];
//        [push setQuery:query];
//        [push setMessage:[NSString stringWithFormat:@"%@ has sent you a new message",recipient]];
//        [push sendPushInBackground];
//    }
}

- (IBAction)setTimeButtonTapped:(id)sender {
    
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
@end
