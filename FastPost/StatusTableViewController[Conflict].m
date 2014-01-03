//
//  StatusViewController.m
//  FastPost
//
//  Created by Huang, Jason on 11/25/13.
//  Copyright (c) 2013 Huang, Jason. All rights reserved.
//

#import "StatusTableViewController.h"
#import "StatusTableCell.h"
#import "Status.h"
#import <Parse/Parse.h>
#import "StatusTableViewHeaderViewController.h"
#import "ComposeNewStatusViewController.h"
#import "ExpirationTimePickerViewController.h"
@interface StatusTableViewController ()<StatusObjectDelegate,FBFriendPickerDelegate,FBViewControllerDelegate,UIAlertViewDelegate, StatusTableViewHeaderViewDelegate,StatusTableCellDelegate,ExpirationTimePickerViewControllerDelegate>{
    NSMutableArray *dataSource;
    NSMutableDictionary *datasource;
    FBFriendPickerViewController *friendPickerVC;
    StatusTableViewHeaderViewController *headerViewVC;
    ExpirationTimePickerViewController *expirationTimePickerVC;
    StatusTableCell *reviveCell;
}

@end

@implementation StatusTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    //add logo
//    UIImageView *view = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]];
//    self.navigationItem.titleView =view;
    
    self.title = @"dwndlr";
//    self.navigationController.navigationBar.titleTextAttributes = [NSDictionary dictionaryWithObject:[UIColor colorWithRed:68.0/255.0 green:154.0/255.0 blue:212.0/255.0 alpha:1] forKey:UITextAttributeTextColor];

    //add refresh control
    UIRefreshControl *control = [[UIRefreshControl alloc] init];
    [control addTarget:self action:@selector(refreshControlTriggered:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = control;
    
    [self fetchNewStatusWithCount:25 andTimeLeft:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)refreshControlTriggered:(UIRefreshControl *)sender{
    [self fetchNewStatusWithCount:25 andTimeLeft:nil];
}

-(void)fetchNewStatusWithCount:(int)count andTimeLeft:(NSNumber *)timeLeft{
    
    PFQuery *queryFriend = [PFQuery queryWithClassName:[PFUser parseClassName]];
    [queryFriend whereKey:@"username" equalTo:[[PFUser currentUser] username]];
    [queryFriend getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        
        if (object && !error) {
            
            PFQuery *query = [PFQuery queryWithClassName:@"Status"];
            //    [query whereKey:@"createdAt" greaterThan:[NSDate date]];
            query.limit = count;
            //use updatedAt is for revive feature. On creation, updatedAt = createdAt, after revive, updatedAt reflects the time
            [query orderByDescending:@"updatedAt"];
//            if (timeLeft) {
//                [query whereKey:@"expirationDate" equalTo:[[NSDate date] dateByAddingTimeInterval:timeLeft.integerValue]];
//            }else{
//                [query whereKey:@"expirationDate" greaterThan:[NSDate date]];
//            }
            [query whereKey:@"expirationTimeInSec" greaterThan:[NSDecimalNumber zero]];
            [query whereKey:@"posterUsername" containedIn:[object objectForKey:@"friends"]];
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if (objects.count != 0) {
                    [self.refreshControl endRefreshing];
                    if (dataSource.count >1) {
                        [dataSource removeAllObjects];
                        for (PFObject *status in objects) {
                            Status *newStatus = [[Status alloc] initWithPFObject:status];
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
                    //if user wants to filter status by timeleft
                    dataSource = nil;
                    [self.tableView reloadData];
                    [self.refreshControl endRefreshing];
                }
                
            }];
        }else{
            //maybe show the dust screen?
        }
    }];
    
    
}

#pragma mark - Status Object Delegate

-(void)statusObjectTimeUpWithObject:(Status *)object{
    NSInteger index = [dataSource indexOfObject:object];
    StatusTableCell *cell = (StatusTableCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    if ([cell.label.text isEqualToString:object.message]) {
//        [cell blurCell];
        [dataSource removeObject:object];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationRight];
        
    }
}

-(void)statusObjectTimerCount:(int)count withStatusObject:(Status *)object{
    NSInteger index = [dataSource indexOfObject:object];
    StatusTableCell *cell = (StatusTableCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    if ([cell.label.text isEqualToString:object.message]) {
        //convert seconds into min and second
        cell.countDownLabel.text = [self minAndTimeFormatWithSecond:object.countDownMessage.intValue];
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
    // Return the number of rows in the section.
    return dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    StatusTableCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.delegate = self;
    // Configure the cell...
    cell.label.text = [[dataSource objectAtIndex:indexPath.row] message];
    cell.usernameLabel.text = [[[dataSource objectAtIndex:indexPath.row] pfObject] objectForKey:@"posterUsername"];
    PFFile *picture = [[[dataSource objectAtIndex:indexPath.row] pfObject] objectForKey:@"picture"];
    cell.countDownLabel.text = [self minAndTimeFormatWithSecond:[[[dataSource objectAtIndex:indexPath.row] countDownMessage] intValue]];
    if (picture != (PFFile *)[NSNull null]) {
        [picture getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                cell.pictureImageView.image = [UIImage imageWithData:data];
            });
            
        }];
    }
//    else{
//        [cell setPlaceHolderImage];
//    }
//    
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [[dataSource objectAtIndex:indexPath.row] startTimer];
    
    //update the count down text
    StatusTableCell *scell = (StatusTableCell *)cell;
    if ([scell.label.text isEqualToString:[dataSource[indexPath.row] message]]) {
        scell.countDownLabel.text = [self minAndTimeFormatWithSecond:[[[dataSource objectAtIndex:indexPath.row] countDownMessage] intValue]];
        if (![scell.countDownLabel.text isEqualToString:@"0:00"]) {
//            [scell unblurCell];
        }else{
            [dataSource removeObjectAtIndex:indexPath.row];
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:indexPath.row inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
//            [scell blurCell];
        }
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    PFFile *picture = [[[dataSource objectAtIndex:indexPath.row] pfObject] objectForKey:@"picture"];
    if (picture != (PFFile *)[NSNull null]) {
        return 400.0f;
    }else{
        return 136.0f;
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
    if (buttonIndex == 1) {
        
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
                PFUser *foundUser = (PFUser *)object;
                [[PFUser currentUser] addObject:foundUser.username forKey:@"friends"];
                [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (!succeeded) {
                        NSLog(@"save new friend failed");
                        [self fetchNewStatusWithCount:25 andTimeLeft:0];
                    }else{
                        NSLog(@"add friend succesffully");
                    }
                }];
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

-(void)reviveStatusButtonTappedOnCell:(StatusTableCell *)cell{
    
    reviveCell = cell;
    
    if (!expirationTimePickerVC) {
        expirationTimePickerVC = [[ExpirationTimePickerViewController alloc] initWithNibName:@"ExpirationTimePickerViewController" bundle:nil];
        expirationTimePickerVC.delegate = self;
        expirationTimePickerVC.titleLabel.text = @"Filter posts by time left";
        expirationTimePickerVC.view.frame = CGRectMake(0,
                                                       (self.tableView.frame.size.height - expirationTimePickerVC.view.frame.size.height)/2,
                                                       expirationTimePickerVC.view.frame.size.width,
                                                       expirationTimePickerVC.view.frame.size.height);
        
        UIToolbar *blurEffectToolBar = [[UIToolbar alloc] initWithFrame:expirationTimePickerVC.view.frame];
        blurEffectToolBar.barStyle = UIBarStyleDefault;
        //set a reference so that can remove it
        expirationTimePickerVC.blurToolBar = blurEffectToolBar;
        
        expirationTimePickerVC.view.alpha = 0.0f;
        expirationTimePickerVC.blurToolBar.alpha = 0.0f;
        [self.view.window addSubview:expirationTimePickerVC.view];
        [self.view.window insertSubview:blurEffectToolBar belowSubview:expirationTimePickerVC.view];
    }
    
    expirationTimePickerVC.pickerView.tag = 0;
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
    
    if (!expirationTimePickerVC) {
        expirationTimePickerVC = [[ExpirationTimePickerViewController alloc] initWithNibName:@"ExpirationTimePickerViewController" bundle:nil];
        expirationTimePickerVC.delegate = self;
        expirationTimePickerVC.titleLabel.text = @"Filter posts by time left";
        expirationTimePickerVC.view.frame = CGRectMake(0,
                                                       (self.tableView.frame.size.height - expirationTimePickerVC.view.frame.size.height)/2,
                                                       expirationTimePickerVC.view.frame.size.width,
                                                       expirationTimePickerVC.view.frame.size.height);
        
        UIToolbar *blurEffectToolBar = [[UIToolbar alloc] initWithFrame:expirationTimePickerVC.view.frame];
        blurEffectToolBar.barStyle = UIBarStyleDefault;
        //set a reference so that can remove it
        expirationTimePickerVC.blurToolBar = blurEffectToolBar;
        
        expirationTimePickerVC.view.alpha = 0.0f;
        expirationTimePickerVC.blurToolBar.alpha = 0.0f;
        [self.view.window addSubview:expirationTimePickerVC.view];
        [self.view.window insertSubview:blurEffectToolBar belowSubview:expirationTimePickerVC.view];
    }
    expirationTimePickerVC.pickerView.tag = 1;
    [UIView animateWithDuration:.3 animations:^{
        expirationTimePickerVC.view.alpha = 1.0f;
        expirationTimePickerVC.blurToolBar.alpha = 1.0f;
    }];
}

#pragma mark - ExpirationTimePickerViewControllerDelegate

-(void)pickerViewExpirationTimeSetToMins:(int)min andSecs:(int)sec andPickerView:(UIPickerView *)pickerView{
    
    //tag 0 is revive picker view, tag 1 is filter by time left picker view
    int timeInterval = min *60 + sec;
    
    if (pickerView.tag == 0) {
        PFObject *status = [dataSource[[[self.tableView indexPathForCell:reviveCell] row]] pfObject];
        
        PFQuery *query = [PFQuery queryWithClassName:@"Status"];
        [query whereKey:@"objectId" equalTo:status.objectId];
        [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if (!error && object) {
                object[@"expirationTimeInSec"] = [NSNumber numberWithInt:timeInterval];
                object[@"expirationDate"] = [NSDate dateWithTimeInterval:timeInterval sinceDate:[NSDate date]];
                [object saveInBackground];
            }
        }];
    }else if(pickerView.tag == 1){
        [self fetchNewStatusWithCount:25 andTimeLeft:[NSNumber numberWithInt:timeInterval]];
    }
}

@end










