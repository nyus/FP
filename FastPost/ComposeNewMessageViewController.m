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
#import "MessageTableViewViewController.h"
static const int FETCH_COUNT = 10;
@interface ComposeNewMessageViewController ()<UITableViewDataSource,UITableViewDelegate,UITextViewDelegate,ExpirationTimePickerViewControllerDelegate>{
    NSRange textRange;
    BOOL messageMode;
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
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [self createTimer];
    
    [self.recipientsTextView becomeFirstResponder];
    self.reviveButton.hidden = YES;
    self.sendButton.enabled = NO;
    
    self.contactArray = [NSMutableArray array];
    self.filteredContactArray = [NSMutableArray array];
    //skip current user's username
    //need to pull self.friends
    dispatch_queue_t queue = dispatch_queue_create("refreshUser", NULL);
    dispatch_async(queue, ^{
        [[PFUser currentUser] refresh];
        for (NSString *username in [[PFUser currentUser] objectForKey:UsersICanMessage]) {
            if([username isEqualToString:[PFUser currentUser].username]){
                continue;
            }
            [self.contactArray addObject:username];
        }
        
        //sort dataSource alphabetically
        [self.contactArray sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        
        for (NSString *username in self.contactArray) {
            [self.filteredContactArray addObject:username];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (self.filteredContactArray.count == 0) {
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
    if (!self.conversation) {
        return;
    }
    
    //here fetch from parse
    PFQuery *query = [PFQuery queryWithClassName:@"Message"];
    [query whereKey:@"objectid" equalTo:self.conversation.objectid];
    [query orderByDescending:@"createdAt"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            
        }
    }];
}

-(void)fetchMessageWithCount:(int)count andOffset:(int)offset{
    
}

//-(void)keyboardWillShow:(NSNotification *)sender{
//    CGRect keyboardRect = [sender.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
//
//    [UIView animateWithDuration:[sender.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue] delay:0 options:[sender.userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue] animations:^{
//        self.enterMessageContainerView.frame = CGRectMake(self.enterMessageContainerView.frame.origin.x,
//                                                          keyboardRect.size.height,
//                                                          self.enterMessageContainerView.frame.size.width,
//                                                          self.enterMessageContainerView.frame.size.height);
//
//    } completion:^(BOOL finished) {
//        self.enterMessageContainerViewBottomSpaceToBottomLayoutContraint.constant = keyboardRect.size.height;
//    }];
//}
//
//-(void)keyboardWillHide:(NSNotification *)sender{
//    
//    CGRect keyboardRect = [sender.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
//    
//    [UIView animateWithDuration:[sender.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue] delay:0 options:[sender.userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue] animations:^{
//        self.enterMessageContainerView.frame = CGRectMake(self.enterMessageContainerView.frame.origin.x,
//                                                          self.enterMessageContainerView.frame.origin.y + keyboardRect.size.height,
//                                                          self.enterMessageContainerView.frame.size.width,
//                                                          self.enterMessageContainerView.frame.size.height);
//        
//    } completion:^(BOOL finished) {
//        self.enterMessageContainerViewBottomSpaceToBottomLayoutContraint.constant = 0;
//    }];
//}

#pragma mark - UITableView

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    if (messageMode) {
        //+1 is the loading cell
        if(self.messageArray.count <FETCH_COUNT){
            //everytime we fetch, we fetch 10 messages, if messageArray.count < 10, then there is no more message to load. no need to add the loading cel
            return self.messageArray.count;
        }else{
            //
            return self.messageArray.count+1;
        }
        
    }else if (self.contactArray.count == 0 || (self.contactArray.count!=0 && self.filteredContactArray.count == 0)) {
        //no contact cell
        return 1;
    }else{
        return self.filteredContactArray.count;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *contactCell = @"contactCell";
    static NSString *messageCell = @"messageCell";
    static NSString *noContactCell = @"noContactCell";
    static NSString *noResultCell = @"noResultCell";
    static NSString *loadingCell = @"loadingCell";
    
    if (messageMode == NO) {
        
        if (self.contactArray.count == 0) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:noContactCell forIndexPath:indexPath];
            return cell;
        }else if(self.filteredContactArray.count == 0){
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:noResultCell forIndexPath:indexPath];
            return cell;
        }else{
            __block AvatarAndUsernameTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:contactCell forIndexPath:indexPath];
            
            //username
            cell.usernameLabel.text = self.filteredContactArray[indexPath.row];
            //profile picture
            [Helper getAvatarForUser:self.filteredContactArray[indexPath.row] avatarType:AvatarTypeMid isHighRes:NO completion:^(NSError *error, UIImage *image) {
                cell.avatarImageView.image = image;
            }];
            
            return cell;
        }
        
    }else{
        
        if(self.messageArray.count <FETCH_COUNT){
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
#warning pull more messages from local
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
        self.filteredContactArray = [self.contactArray mutableCopy];
    }else{
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@",self.recipientsTextView.text];
        NSArray *array = [self.contactArray filteredArrayUsingPredicate:predicate];
        self.filteredContactArray = nil;
        self.filteredContactArray = [array mutableCopy];
    }
    [self.tableView reloadData];
}

#pragma mark - UITextView

-(void)textViewDidChange:(UITextView *)textView{
    
    if (textView==self.enterMessageTextView) {
        [self performSelector:@selector(scrollTextViewToVisible:) withObject:self.enterMessageTextView afterDelay:0.1];
    }else if (textView == self.recipientsTextView){
        self.sendButton.enabled = NO;
        messageMode = NO;
        [self filterContacts];
    }
}

//-(void)scrollTextViewToVisible:(UITextView *)textView{
//    [super scrollTextViewToVisible:textView];
//}

-(void)textViewDidBeginEditing:(UITextView *)textView{
    [UIView animateWithDuration:.3 animations:^{
        self.expirationTimePickerVC.view.alpha = 0.0f;
        self.expirationTimePickerVC.blurToolBar.alpha = 0.0f;
    }];
}

- (IBAction)cancelButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
