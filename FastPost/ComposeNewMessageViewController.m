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
#import "ConversationsTableViewViewController.h"
#import "SharedDataManager.h"
#import "DisplayMessageViewController.h"
static const int FETCH_COUNT = 10;
@interface ComposeNewMessageViewController (){
    NSRange textRange;
    BOOL messageMode;
}
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

    //this is for setting constraint in the parent vc. need to be set become becomeFirstResponder
    self.isFromPushSegue = NO;
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
        //the intersection of these two arrays are usersICanMessage
        NSArray *usersIAllowToFollowMe = [[PFUser currentUser] objectForKey:@"usersIAllowToFollowMe"];
        NSArray *usersAllowMeToFollow = [[PFUser currentUser] objectForKey:@"usersAllowMeToFollow"];//this array contains self
        NSMutableSet *set = [NSMutableSet set];
        for (NSString *username in usersIAllowToFollowMe) {
            [set addObject:username];
        }
        for (NSString *username in usersAllowMeToFollow) {
            if([username isEqualToString:[PFUser currentUser].username]){
                continue;
            }
            if ([set containsObject:username]) {
                [self.contactArray addObject:username];
            }
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

-(void)fetchMessageWithCount:(int)count andOffset:(int)offset{
    
}

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
        return 0;
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

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if ([cell isKindOfClass:[AvatarAndUsernameTableViewCell class]]) {
        AvatarAndUsernameTableViewCell *contact = (AvatarAndUsernameTableViewCell *)cell;
        self.recipientsTextView.text = contact.usernameLabel.text;
    
        //see if an existing conversation with self and the recipient(s) already exists
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Conversation"];
        NSString *hashString = [Helper computeHashStringForParticipantsArray:@[[PFUser currentUser].username, self.recipientsTextView.text]];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.objectid == %@",hashString];
        fetchRequest.predicate = predicate;
        NSError *fetchError;
        NSArray *result = [[SharedDataManager sharedInstance].managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
        if (result.count>0) {
            self.conversation = result[0];
        }

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



-(void)textViewDidBeginEditing:(UITextView *)textView{
    [UIView animateWithDuration:.3 animations:^{
        self.expirationTimePickerVC.view.alpha = 0.0f;
        self.expirationTimePickerVC.blurToolBar.alpha = 0.0f;
    }];
}

- (IBAction)cancelButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)sendButtonTapped:(id)sender{
    //in the parent implementaion of this method, we need to specify the currently in-use dataSource so that we can add objects into the right place, and also the tableview will reload correctly
    if (messageMode) {
        if (!self.messageArray) {
            self.messageArray = [NSMutableArray array];
        }
        self.dataSource = self.messageArray;
    }else{
        self.dataSource = self.filteredContactArray;
    }
    [super sendButtonTapped:sender];
    
    //swap the view controllers. simulate iMessage's behavior
    UINavigationController *generalNav = (UINavigationController *)self.presentingViewController;
    UITabBarController *tabbarVC = generalNav.viewControllers[0];
    UINavigationController *detailNav = (UINavigationController *)tabbarVC.selectedViewController;
    DisplayMessageViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"viewAndInputMessage"];
    vc.conversation = self.conversation;
    [self dismissViewControllerAnimated:NO completion:nil];
    [detailNav setViewControllers:@[detailNav.viewControllers[0],vc] animated:NO];
}
@end
