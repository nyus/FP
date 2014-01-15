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
#define BACKGROUND_CELL_HEIGHT 300.0f
#define ORIGIN_Y_CELL_MESSAGE_LABEL 86.0f
@interface StatusViewController ()<StatusObjectDelegate,FBFriendPickerDelegate,FBViewControllerDelegate,UIAlertViewDelegate, StatusTableViewHeaderViewDelegate,StatusTableViewCellDelegate,ExpirationTimePickerViewControllerDelegate>{
    
    NSMutableArray *dataSource;
    FBFriendPickerViewController *friendPickerVC;
    StatusTableViewHeaderViewController *headerViewVC;
    ExpirationTimePickerViewController *expirationTimePickerVC;
    StatusTableViewCell *cellToRevive;
    UIRefreshControl *refreshControl;
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

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    //add refresh control
    [self addRefreshControll];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if (dataSource==nil) {
        [self fetchNewStatusWithCount:25 remainingTime:nil];
    }
    else{
        //this is a fix for a bug, where you come back from compose, the views in the cell get messed up
        [self.tableView reloadData];
    }

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
            if (dataSource.count > 0) {
                [dataSource removeAllObjects];
                
                for (int i = 0 ; i<objects.count; i++) {
                    Status *newStatus = [[Status alloc] initWithPFObject:objects[i]];
                    newStatus.delegate = self;
                    if (!dataSource) {
                        dataSource = [NSMutableArray array];
                    }
                    [dataSource addObject:newStatus];
                }
                
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
            }else{
                for (PFObject *status in objects) {
                    Status *newStatus = [[Status alloc] initWithPFObject:status];
                    newStatus.delegate = self;
                    if (!dataSource) {
                        dataSource = [NSMutableArray array];
                    }
                    [dataSource addObject:newStatus];
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
    NSInteger index = [dataSource indexOfObject:object];
    StatusTableViewCell *cell = (StatusTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    if ([cell.statusCellMessageLabel.text isEqualToString:[object.pfObject objectForKey:@"message"]]) {
        //        [cell blurCell];
        [dataSource removeObject:object];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationRight];
        //if there is no status anymore, need to reload to show the background cell
        if(dataSource.count == 0){
            //setting dataSource to nil prevents talbeview from crashing.
            dataSource = nil;
            [self.tableView reloadData];
        }
    }
}

-(void)statusObjectTimerCount:(int)count withStatusObject:(Status *)object{
    NSInteger index = [dataSource indexOfObject:object];
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
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(!dataSource){
        //return background cell
        [self fetchNewStatusWithCount:25 remainingTime:nil];
        return 1;
    }else{
        // Return the number of rows in the section.
        return dataSource.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if(!dataSource || dataSource.count == 0){
        //no status background cell
        static NSString *CellIdentifier = @"BackgroundCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        return cell;
    }else{
        static NSString *CellIdentifier = @"Cell";
        StatusTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        cell.delegate = self;
        // Configure the cell...
        cell.statusCellMessageLabel.text = [[dataSource objectAtIndex:indexPath.row] pfObject][@"message"];
        cell.statusCellUsernameLabel.text = [[[dataSource objectAtIndex:indexPath.row] pfObject] objectForKey:@"posterUsername"];
        BOOL revivable = [[dataSource[indexPath.row] pfObject][@"revivable"] boolValue];
        if (!revivable) {
            cell.statusCellReviveButton.hidden = YES;
        }
        
        //
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"HH:mm MM/dd/yy"];
        NSString *str = [formatter stringFromDate:[[dataSource objectAtIndex:indexPath.row] pfObject].updatedAt];
        cell.statusCellDateLabel.text = str;
        
        //if user avatar is saved, pull locally; otherwise pull from server and save it locally
        [Helper getAvatarForUser:[PFUser currentUser].username forImageView:cell.statusCellAvatarImageView];
        
        PFFile *picture = [[[dataSource objectAtIndex:indexPath.row] pfObject] objectForKey:@"picture"];
        cell.statusCellCountDownLabel.text = [self minAndTimeFormatWithSecond:[[dataSource[indexPath.row] countDownMessage] intValue]];
        if (picture != (PFFile *)[NSNull null] && picture != nil) {
            
            //add spinner on image view to indicate pulling image
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            spinner.center = CGPointMake((int)cell.statusCellPhotoImageView.frame.size.width/2, (int)cell.statusCellPhotoImageView.frame.size.height/2);
            [cell.statusCellPhotoImageView addSubview:spinner];
            [spinner startAnimating];

            [picture getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                
                if (data && !error) {
                    cell.statusCellPhotoImageView.image = [UIImage imageWithData:data];
                }else{
                    NSLog(@"error (%@) getting status photo with status id %@",error.localizedDescription,[[[dataSource objectAtIndex:indexPath.row] pfObject] objectId]);
                }
                
                [spinner stopAnimating];
            }];
        }
        
        return cell;
    }
    
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    
    //for non background cell
    if(dataSource && dataSource.count != 0){
        [[dataSource objectAtIndex:indexPath.row] startTimer];
        
        //update the count down text
        StatusTableViewCell *scell = (StatusTableViewCell *)cell;
        if ([scell.statusCellMessageLabel.text isEqualToString:[dataSource[indexPath.row] pfObject][@"message"]]) {
            scell.statusCellCountDownLabel.text = [self minAndTimeFormatWithSecond:[[dataSource[indexPath.row] countDownMessage] intValue]];
            if (![scell.statusCellCountDownLabel.text isEqualToString:@"0:00"]) {
            }else{
                [dataSource removeObjectAtIndex:indexPath.row];
                [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:indexPath.row inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
                
                if(dataSource.count == 0){
                    dataSource = nil;
                    [self.tableView reloadData];
                }
            }
        }
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if(!dataSource || dataSource.count == 0){
        return BACKGROUND_CELL_HEIGHT;
    }else{
       
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 280, 20)];
        label.numberOfLines = 0;
        label.font = [UIFont fontWithName:@"AvenirNextCondensed-Regular" size:17];
        label.text = [dataSource[indexPath.row] pfObject][@"message"];
        [label sizeToFit];
        
        //determine if there is a picture
        
        PFFile *picture = [[[dataSource objectAtIndex:indexPath.row] pfObject] objectForKey:@"picture"];
        if (picture == (PFFile *)[NSNull null] || picture == nil) {
            //68 y origin of label
            return ORIGIN_Y_CELL_MESSAGE_LABEL + label.frame.size.height + 10;
        }else{
            //68 y origin of label, 204 height of picture image view
            return ORIGIN_Y_CELL_MESSAGE_LABEL + label.frame.size.height + 10 + 204 + 10;
        }
        
    }
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    headerViewVC = [[StatusTableViewHeaderViewController alloc] initWithNibName:@"StatusTableViewHeaderViewController" bundle:nil];
    headerViewVC.delegate = self;
    return headerViewVC.view;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 44.0f;
}

#pragma mark - UIAlertViewDelegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    //find button hit
    if (alertView.tag == 99 && buttonIndex == 1) {
        
        NSString *key = nil;
        if ([[[alertView textFieldAtIndex:0] text] rangeOfString:@"@"].location == NSNotFound) {
            key = @"username";
        }else{
            key = @"email";
        }
        PFQuery *queryExist = [PFQuery queryWithClassName:[PFUser parseClassName]];
        [queryExist whereKey:key equalTo:[[alertView textFieldAtIndex:0] text]];
        [queryExist getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            //this user doenst exist
            if (!object) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"This user doesn't exist" delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
                [alert show];
            }else{
                
                //add the person that user wants to follow in user's friends array on server
                PFUser *foundUser = (PFUser *)object;
                [[PFUser currentUser] addObject:foundUser.username forKey:@"friends"];
                [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (!succeeded) {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:@"Failed to follow %@, please try again",foundUser.username] delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
                        [alert show];
                    }else{
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:@"Success! You can now see posts from %@",foundUser.username] delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
                        [alert show];
                    }
                }];
                
                //add self to the person that self follows to person's follower array on server
                [foundUser addObject:[PFUser currentUser].username forKey:@"followers"];
                [foundUser saveInBackground];
            }
        }];
    }
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
    
    //for now it would be adding email
    UIAlertView *addFriendAlert = [[UIAlertView alloc] initWithTitle:nil message:@"Search by email or username" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Find", nil];
    addFriendAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
    addFriendAlert.tag = 99;
    [addFriendAlert show];
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
    }];
}

#pragma mark - ExpirationTimePickerViewControllerDelegate

-(void)revivePickerViewExpirationTimeSetToMins:(int)min andSecs:(int)sec andPickerView:(UIPickerView *)pickerView{
    Status *status = dataSource[[[self.tableView indexPathForCell:cellToRevive] row]];
    
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
