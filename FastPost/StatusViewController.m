//
//  StatusViewController.m
//  FastPost
//
//  Created by Sihang Huang on 1/6/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "StatusViewController.h"
#import "StatusTableViewCell.h"
#import "Status.h"
#import <Parse/Parse.h>
#import "StatusTableViewHeaderViewController.h"
#import "ComposeNewStatusViewController.h"
#import "LogInViewController.h"
#import "ProfileViewController.h"
#import "Helper.h"
#import "FriendQuestViewController.h"
#import "CommentStatusViewController.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "FPLogger.h"
#define BACKGROUND_CELL_HEIGHT 300.0f
#define ORIGIN_Y_CELL_MESSAGE_LABEL 86.0f
@interface StatusViewController ()<StatusObjectDelegate,FBFriendPickerDelegate,FBViewControllerDelegate, StatusTableViewHeaderViewDelegate,UIActionSheetDelegate, MFMailComposeViewControllerDelegate,UIAlertViewDelegate>{
    
    FBFriendPickerViewController *friendPickerVC;
    StatusTableViewHeaderViewController *headerViewVC;
    StatusTableViewCell *cellToRevive;
    UIRefreshControl *refreshControl;
    UITapGestureRecognizer *tapGesture;
    FriendQuestViewController *friendQusetVC;
    
    NSString *statusIdToPass;
}

@end

@implementation StatusViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //add logo
    //    UIImageView *view = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]];
    //    self.navigationItem.titleView =view;
    
    LogInViewController *vc = (LogInViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"logInView"];
    [self presentViewController:vc animated:NO completion:nil];

    tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [self.view addGestureRecognizer:tapGesture];
    
    //add refresh control
    [self addRefreshControll];
    
//#warning version 1.0 doesnt require like and comment
    //if yes, table view cell will make room for like, comment and revive buttons
    self.needSocialButtons = NO;
    //
    self.dataSource = [NSMutableArray array];
    
    //register for UIApplicationWillEnterForegroundNotification notification since timer will not work in the background for more than 10 mins. when user comes back, we refresh table view to update the status count down time
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
}

-(void)handleApplicationWillEnterForeground{
//    [self fetchNewStatusWithCount:25 remainingTime:nil];
}

-(void)handleTapGesture:(id)sender{
    if (friendQusetVC.isOnScreen) {
        friendQusetVC.isOnScreen = NO;
        [friendQusetVC removeSelfFromParent];
        [self.view endEditing:YES];
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    //stop observing UIApplicationWillEnterForegroundNotification
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self fetchNewStatusWithCount:25 remainingTime:nil];

//    //this is a fix for a bug, where you come back from compose, the views in the cell get messed up
//    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)addRefreshControll{
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshControlTriggered:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];
}

-(void)refreshControlTriggered:(UIRefreshControl *)sender{
    [self fetchNewStatusWithCount:25 remainingTime:nil];
}

-(void)fetchNewStatusWithCount:(int)count remainingTime:(NSNumber *)remainingTimeInSec{
    
    [[PFUser currentUser] refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        PFQuery *query = [PFQuery queryWithClassName:@"Status"];
        query.limit = count;
        [query orderByDescending:@"createdAt"];
        [query whereKey:@"expirationDate" greaterThan:[NSDate date]];
        
        if (remainingTimeInSec) {
            [query whereKey:@"expirationDate" lessThan:[[NSDate date] dateByAddingTimeInterval:remainingTimeInSec.intValue]];
        }
        
        [query whereKey:@"posterUsername" containedIn:[[PFUser currentUser] objectForKey:@"usersAllowMeToFollow"]];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            
            if (objects.count != 0) {
                
                [refreshControl endRefreshing];
                if (self.dataSource.count > 0) {
                    [self.dataSource removeAllObjects];
                    
                    for (int i = 0 ; i<objects.count; i++) {
                        Status *newStatus = [[Status alloc] initWithPFObject:objects[i]];
                        newStatus.delegate = self;
                        if (!self.dataSource) {
                            self.dataSource = [NSMutableArray array];
                        }
                        [self.dataSource addObject:newStatus];
                    }
                    

                    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
                    
                }else{
                    for (PFObject *status in objects) {
                        Status *newStatus = [[Status alloc] initWithPFObject:status];
                        newStatus.delegate = self;
                        if (!self.dataSource) {
                            self.dataSource = [NSMutableArray array];
                        }
                        [self.dataSource addObject:newStatus];
                    }
                    
                    [self.tableView reloadData];
                }
            }else{
                //
                NSLog(@"0 items fetched from parse");
                [refreshControl endRefreshing];
            }
        }];
    }];
}

#pragma mark - Status Object Delegate

-(void)statusObjectTimeUpWithObject:(Status *)object{
    NSInteger index = [self.dataSource indexOfObject:object];
    StatusTableViewCell *cell = (StatusTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    if ([cell.statusCellMessageLabel.text isEqualToString:object.message]) {
        //        [cell blurCell];
        [self removeStoredHeightForStatus:object];
        [self.dataSource removeObject:object];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationRight];
        //if there is no status anymore, need to reload to show the background cell
        if(self.dataSource.count == 0){
            //setting self.dataSource to nil prevents talbeview from crashing.
            self.dataSource = nil;
            [self.tableView reloadData];
        }
    }
}

-(void)statusObjectTimerCount:(int)count withStatusObject:(Status *)object{
    NSInteger index = [self.dataSource indexOfObject:object];
    StatusTableViewCell *cell = (StatusTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    if ([cell.statusCellMessageLabel.text isEqualToString:object.message]) {
        //convert seconds into min and second
        cell.statusCellCountDownLabel.text = [self minAndTimeFormatWithSecond:object.countDownMessage.intValue];
    }
}

-(NSString *)minAndTimeFormatWithSecond:(int)seconds{
    return [NSString stringWithFormat:@"%d:%02d",seconds/60,seconds%60];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [super numberOfSectionsInTableView:tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [super tableView:tableView numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}


-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    
    //for non background cell
    if(self.dataSource && self.dataSource.count != 0){
        [[self.dataSource objectAtIndex:indexPath.row] startTimer];
        
        //update the count down text
        StatusTableViewCell *scell = (StatusTableViewCell *)cell;
        if ([scell.statusCellMessageLabel.text isEqualToString:[self.dataSource[indexPath.row] message]]) {
            scell.statusCellCountDownLabel.text = [self minAndTimeFormatWithSecond:[[self.dataSource[indexPath.row] countDownMessage] intValue]];
            if (![scell.statusCellCountDownLabel.text isEqualToString:@"0:00"]) {
            }else{
                [self.dataSource removeObjectAtIndex:indexPath.row];
                [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:indexPath.row inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
                
                if(self.dataSource.count == 0){
                    self.dataSource = nil;
                    [self.tableView reloadData];
                }
            }
        }
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    headerViewVC = [[StatusTableViewHeaderViewController alloc] initWithNibName:@"StatusTableViewHeaderViewController" bundle:nil];
    headerViewVC.delegate = self;
    return headerViewVC.view;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 44.0f;
}


#pragma mark - FBFriendPickerDelegate

-(void)friendPickerViewController:(FBFriendPickerViewController *)friendPicker handleError:(NSError *)error{
    NSLog(@"friendPickerViewController error %@",error);
}

-(void)friendPickerViewControllerSelectionDidChange:(FBFriendPickerViewController *)friendPicker{
    
}

#pragma mark - FBViewControllerDelegate
- (void)facebookViewControllerCancelWasPressed:(id)sender{
    [self dismissViewControllerAnimated:YES completion:^{
        friendPickerVC = nil;
    }];
    
}

- (void)facebookViewControllerDoneWasPressed:(id)sender{
    [self dismissViewControllerAnimated:YES completion:^{
        //        NSArray *selectedFriends = friendPickerVC.selection;
    }];
}

#pragma mark - StatusTableCellDelegate

-(void)usernameLabelTappedOnCell:(StatusTableViewCell *)cell{
    [self performSegueWithIdentifier:@"toProfile" sender:self];
}

-(int)convertCountDownTextToSecond:(NSString *)coundDownText{
    NSArray *components = [coundDownText componentsSeparatedByString:@":"];
    
    int min = [[components objectAtIndex:0] intValue];
    int sec = [[components objectAtIndex:1] intValue];
    
    return min*60+sec;
}

-(void)likeButtonTappedOnCell:(StatusTableViewCell *)cell{
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    Status *status = self.dataSource[indexPath.row];
    
    PFQuery *query = [[PFQuery alloc] initWithClassName:@"Status"];
    [query whereKey:@"objectId" equalTo:status.objectid];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!error) {
            
            //create like object
            PFObject *like = [[PFObject alloc] initWithClassName:@"Like"];
            like[@"senderUsername"] = [PFUser currentUser].username;
            like[@"statusId"] = status.objectid;
            
            //increate like count on Status object
            object[@"likeCount"] = [NSNumber numberWithInt:[object[@"likeCount"] intValue] +1];
            
            [like saveInBackground];
            [object saveInBackground];
        }
    }];

}

-(void)commentButtonTappedOnCell:(StatusTableViewCell *)cell{
    
    //take user to comment status view controller
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    Status *status = self.dataSource[indexPath.row];
    statusIdToPass = status.objectid;
    [self performSegueWithIdentifier:@"toCommentStatus" sender:self];

}

-(void)reviveAnimationDidEndOnCell:(StatusTableViewCell *)cell withProgress:(float)percentage{
    NSLog(@"progress %f",percentage);
}
#pragma mark - StatusTableHeaderViewDelegate

-(void)tbHeaderAddFriendButtonTapped{
    
    if (!friendQusetVC) {
        friendQusetVC = [[UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil]instantiateViewControllerWithIdentifier:@"friendQuest"];
        friendQusetVC.view.frame = CGRectMake(0, (self.view.frame.size.height-300)/2, friendQusetVC.view.frame.size.width, 300);
        friendPickerVC.view.alpha = 0.0f;
        [self.view addSubview:friendQusetVC.view];
    }
    
    
    [friendQusetVC.textField becomeFirstResponder];

    [UIView animateWithDuration:.3 animations:^{
        friendQusetVC.blurToolBar.alpha = 1.0f;
        friendQusetVC.view.alpha = 1.0f;
        
    } completion:^(BOOL finished) {
        friendQusetVC.isOnScreen = YES;
    }];
    
    //Facebook add friend code
//    friendPickerVC = [[FBFriendPickerViewController alloc] initWithNibName:nil bundle:nil];
//    friendPickerVC.title = @"Select Friends";
//    [friendPickerVC loadData];
//    friendPickerVC.delegate = self;
//    [self presentViewController:friendPickerVC animated:YES completion:nil];
}

-(void)tbHeaderComposeNewStatusButtonTapped{
    [self performSegueWithIdentifier:@"toCompose" sender:self];
}

-(void)tbHeaderSettingButtonTapped{
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"About",@"Contact",@"Log out",@"Send Disgnosis", nil];
    [actionSheet showFromTabBar:self.tabBarController.tabBar];
    
    
//this is fiter posts by time left
    /*
    //filter button typed
    if (!expirationTimePickerVC) {
        expirationTimePickerVC = [[ExpirationTimePickerViewController alloc] initWithNibName:@"ExpirationTimePickerViewController" bundle:nil type:PickerTypeFilter];
        expirationTimePickerVC.delegate = self;
        expirationTimePickerVC.view.frame = CGRectMake(0,
                                                       (self.tableView.frame.size.height - expirationTimePickerVC.view.frame.size.height)/2,
                                                       expirationTimePickerVC.view.frame.size.width,
                                                       expirationTimePickerVC.view.frame.size.height);
        expirationTimePickerVC.titleLabel.text = @"Filter posts by time left";
        
        UIToolbar *blurEffectToolBar = [[UIToolbar alloc] initWithFrame:expirationTimePickerVC.view.frame];
        blurEffectToolBar.barStyle = UIBarStyleDefault;
        //set a reference so that can remove it
        expirationTimePickerVC.blurToolBar = blurEffectToolBar;
        
        expirationTimePickerVC.view.alpha = 0.0f;
        expirationTimePickerVC.blurToolBar.alpha = 0.0f;
        [self.view.window addSubview:expirationTimePickerVC.view];
        [self.view.window insertSubview:blurEffectToolBar belowSubview:expirationTimePickerVC.view];
    }
    
    expirationTimePickerVC.type = PickerTypeFilter;
    
    [UIView animateWithDuration:.3 animations:^{
        expirationTimePickerVC.view.alpha = 1.0f;
        expirationTimePickerVC.blurToolBar.alpha = 1.0f;
    } completion:^(BOOL finished) {
        expirationTimePickerVC.isOnScreen = YES;
    }];
    */
}

#pragma mark - UIActionSheetDelegate

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    //0:About 1:Contact 2:Log out
    if (buttonIndex == 0) {
        
    }else if (buttonIndex == 1){
        MFMailComposeViewController *vc = [[MFMailComposeViewController alloc] init];
        [vc setToRecipients:@[@"dwndlr@gmail.com"]];
        vc.mailComposeDelegate = self;

        [self presentViewController:vc animated:YES completion:nil];
    }else if (buttonIndex == 2){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Are you sure you want to log out?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Log out", nil];
        [alert show];
    }else if (buttonIndex == 3){
        [FPLogger sendReport];
    }
}

#pragma mark - ExpirationTimePickerViewControllerDelegate

//-(void)revivePickerViewExpirationTimeSetToMins:(NSInteger)min andSecs:(NSInteger)sec andPickerView:(UIPickerView *)pickerView{
//    Status *status = self.dataSource[[[self.tableView indexPathForCell:cellToRevive] row]];
//    
//    //add time to status remotely
//    int timeInterval = (int)min * 60 + (int)sec + status.countDownMessage.intValue;
//    
//    PFQuery *queryStatusObj = [[PFQuery alloc] initWithClassName:@"Status"];
//    [queryStatusObj whereKey:@"objectId" equalTo:status.objectid];
//    [queryStatusObj getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
//        if (!error) {
//            object[@"expirationTimeInSec"] = [NSNumber numberWithInt:timeInterval];
//            object[@"expirationDate"] = [NSDate dateWithTimeInterval:timeInterval sinceDate:[NSDate date]];
//            [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
//                if (succeeded) {
//                    [FPLogger record:[NSString stringWithFormat:@"revive status: %@ succeeded",object]];
//                }else{
//                    [FPLogger record:[NSString stringWithFormat:@"revive status: %@ failed",object]];
//                }
//            }];
//        }
//    }];
//    
//    //add time to the status locally
//    status.countDownMessage = [NSString stringWithFormat:@"%d",timeInterval];
//}
//
//-(void)filterPickerViewExpirationTimeSetToLessThanMins:(int)min andPickerView:(UIPickerView *)pickerView{
//    [self fetchNewStatusWithCount:25 remainingTime:[NSNumber numberWithInt:min*60]];
//}

#pragma mark - UISegue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"toCommentStatus"]){
        CommentStatusViewController *vc = (CommentStatusViewController *)segue.destinationViewController;
        vc.statusObjectId = statusIdToPass;
    }else if ([segue.identifier isEqualToString:@"toUserProfile"]){
        ProfileViewController *pvc = (ProfileViewController *)segue.destinationViewController;
        UIButton *btn = (UIButton *)sender;
        pvc.userNameOfUserProfileToDisplay = btn.titleLabel.text;
    }
}

#pragma mark - MFMail

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - UIAlertViewDelegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    //log out alert
    if (buttonIndex == 1) {
        [PFUser logOut];
        LogInViewController *vc = (LogInViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"logInView"];
        [self presentViewController:vc animated:NO completion:nil];
    }
}
@end
