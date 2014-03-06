//
//  StatusViewController.m
//  FastPost
//
//  Created by Sihang Huang on 1/6/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "StatusViewController.h"
#import "StatusTableViewCell.h"
#import "Status.h"
#import <Parse/Parse.h>
#import "StatusTableViewHeaderViewController.h"
#import "ComposeNewStatusViewController.h"
#import "ExpirationTimePickerViewController.h"
#import "LogInViewController.h"
#import "ProfileViewController.h"
#import "Helper.h"
#import "FriendQuestViewController.h"
#define BACKGROUND_CELL_HEIGHT 300.0f
#define ORIGIN_Y_CELL_MESSAGE_LABEL 86.0f
@interface StatusViewController ()<StatusObjectDelegate,FBFriendPickerDelegate,FBViewControllerDelegate, StatusTableViewHeaderViewDelegate,ExpirationTimePickerViewControllerDelegate>{
    
    FBFriendPickerViewController *friendPickerVC;
    StatusTableViewHeaderViewController *headerViewVC;
    ExpirationTimePickerViewController *expirationTimePickerVC;
    StatusTableViewCell *cellToRevive;
    UIRefreshControl *refreshControl;
    UITapGestureRecognizer *tapGesture;
    FriendQuestViewController *friendQusetVC;
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
    [self presentViewController:vc animated:NO completion:^{
        
    }];

    tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [self.view addGestureRecognizer:tapGesture];
    
    //add refresh control
    [self addRefreshControll];
    
    //
    self.dataSource = [NSMutableArray array];
}

-(void)handleTapGesture:(id)sender{
    if (friendQusetVC.isOnScreen) {
        friendQusetVC.isOnScreen = NO;
        [friendQusetVC removeSelfFromParent];
        [self.view endEditing:YES];
    }
    
    if (expirationTimePickerVC.isOnScreen) {
        [expirationTimePickerVC removeSelfFromParent];
        [self.view endEditing:YES];
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self fetchNewStatusWithCount:25 remainingTime:nil];

    //this is a fix for a bug, where you come back from compose, the views in the cell get messed up
    [self.tableView reloadData];
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
    
    //refresh to get the most recent @"friends"
    [[PFUser currentUser] refresh];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Status"];
    query.limit = count;
    [query orderByDescending:@"createdAt"];
    [query whereKey:@"expirationDate" greaterThan:[NSDate date]];
    
    if (remainingTimeInSec) {
        [query whereKey:@"expirationDate" lessThan:[[NSDate date] dateByAddingTimeInterval:remainingTimeInSec.intValue]];
    }
    [query whereKey:@"posterUsername" containedIn:[[PFUser currentUser] objectForKey:@"friends"]];
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
}

#pragma mark - Status Object Delegate

-(void)statusObjectTimeUpWithObject:(Status *)object{
    NSInteger index = [self.dataSource indexOfObject:object];
    StatusTableViewCell *cell = (StatusTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    if ([cell.statusCellMessageLabel.text isEqualToString:[object.pfObject objectForKey:@"message"]]) {
        //        [cell blurCell];
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
    if ([cell.statusCellMessageLabel.text isEqualToString:[object.pfObject objectForKey:@"message"]]) {
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
//    if(!self.dataSource){
//        //return background cell
//        [self fetchNewStatusWithCount:25 remainingTime:nil];
//        return 1;
//    }else{
        // Return the number of rows in the section.
        return [super tableView:tableView numberOfRowsInSection:section];
//    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
//    if(!self.dataSource || self.dataSource.count == 0){
//        //no status background cell
//        static NSString *CellIdentifier = @"BackgroundCell";
//        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
//        
//        return cell;
//    }else{
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];
//    }
    
}


-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    
    //for non background cell
    if(self.dataSource && self.dataSource.count != 0){
        [[self.dataSource objectAtIndex:indexPath.row] startTimer];
        
        //update the count down text
        StatusTableViewCell *scell = (StatusTableViewCell *)cell;
        if ([scell.statusCellMessageLabel.text isEqualToString:[self.dataSource[indexPath.row] pfObject][@"message"]]) {
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

-(void)reviveStatusButtonTappedOnCell:(StatusTableViewCell *)cell{
    
    cellToRevive = cell;
    
    if (!expirationTimePickerVC) {
        expirationTimePickerVC = [[ExpirationTimePickerViewController alloc] initWithNibName:@"ExpirationTimePickerViewController" bundle:nil type:PickerTypeRevive];
        expirationTimePickerVC.delegate = self;
        expirationTimePickerVC.view.frame = CGRectMake(0,
                                                       (self.tableView.frame.size.height - expirationTimePickerVC.view.frame.size.height)/2,
                                                       expirationTimePickerVC.view.frame.size.width,
                                                       expirationTimePickerVC.view.frame.size.height);
        expirationTimePickerVC.titleLabel.text = @"Revive Status";
        
        UIToolbar *blurEffectToolBar = [[UIToolbar alloc] initWithFrame:expirationTimePickerVC.view.frame];
        blurEffectToolBar.barStyle = UIBarStyleDefault;
        //set a reference so that can remove it
        expirationTimePickerVC.blurToolBar = blurEffectToolBar;
        
        expirationTimePickerVC.view.alpha = 0.0f;
        expirationTimePickerVC.blurToolBar.alpha = 0.0f;
        [self.view.window addSubview:expirationTimePickerVC.view];
        [self.view.window insertSubview:blurEffectToolBar belowSubview:expirationTimePickerVC.view];
    }
    
    expirationTimePickerVC.type = PickerTypeRevive;
    
    [UIView animateWithDuration:.3 animations:^{
        expirationTimePickerVC.view.alpha = 1.0f;
        expirationTimePickerVC.blurToolBar.alpha = 1.0f;
    }];
}

#pragma mark - StatusTableHeaderViewDelegate

-(void)tbHeaderAddFriendButtonTapped{
    
    if (!friendQusetVC) {
        friendQusetVC = [[UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil]instantiateViewControllerWithIdentifier:@"friendQuest"];
        friendQusetVC.view.frame = CGRectMake(0, (self.view.frame.size.height-300)/2, friendQusetVC.view.frame.size.width, 300);
        friendPickerVC.view.alpha = 0.0f;
        [self.view addSubview:friendQusetVC.view];
    }
    

//    friendQusetVC.blurToolBar.alpha = 1.0f;
//    [UIView animateWithDuration:.2 animations:^{
    
        friendQusetVC.view.alpha = 1.0f;
    
        
//    } completion:^(BOOL finished) {
        friendQusetVC.isOnScreen = YES;
//    }];
    
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
}

#pragma mark - ExpirationTimePickerViewControllerDelegate

-(void)revivePickerViewExpirationTimeSetToMins:(int)min andSecs:(int)sec andPickerView:(UIPickerView *)pickerView{
    Status *status = self.dataSource[[[self.tableView indexPathForCell:cellToRevive] row]];
    
    //add time to status remotely
    int timeInterval = min * 60 + sec + status.countDownMessage.intValue;
    
    status.pfObject[@"expirationTimeInSec"] = [NSNumber numberWithInt:timeInterval];
    status.pfObject[@"expirationDate"] = [NSDate dateWithTimeInterval:timeInterval sinceDate:[NSDate date]];
    [status.pfObject saveInBackground];
    
    //add time to the status locally
    status.countDownMessage = [NSString stringWithFormat:@"%d",timeInterval];
}

-(void)filterPickerViewExpirationTimeSetToLessThanMins:(int)min andPickerView:(UIPickerView *)pickerView{
    [self fetchNewStatusWithCount:25 remainingTime:[NSNumber numberWithInt:min*60]];
}

#pragma mark - UISegue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"toProfile"]){
        ProfileViewController *pvc = (ProfileViewController *)segue.destinationViewController;
        pvc.presentingSource = @"statusViewController";
    }
}
@end
