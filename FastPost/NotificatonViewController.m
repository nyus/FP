//
//  NotificatonViewController.m
//  FastPost
//
//  Created by Huang, Sihang on 3/7/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "NotificatonViewController.h"
#import <Parse/Parse.h>
#import "FriendQuestTableViewCell.h"
#import "Helper.h"
#import "FPLogger.h"
@interface NotificatonViewController ()<UITableViewDataSource,UITableViewDelegate,FriendQuestTableViewCellDelegate>{
    //this contains friend quests
    NSMutableArray *dataSource;
}

@end

@implementation NotificatonViewController

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
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.delaysContentTouches = NO;
    self.tableView.canCancelContentTouches = YES;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    //pull follow request
    [self pullFriendRequest];
    //pull revive, like ,comment notification

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)pullFriendRequest{
    //FriendRequest.requestStatus
    //1. accepted 2. denied 3. not now 4. new request
    PFQuery *query = [[PFQuery alloc] initWithClassName:@"FriendRequest"];
    //dont pull accepted/denied request
    [query whereKey:@"requestStatus" greaterThanOrEqualTo:[NSNumber numberWithInt:3]];
    [query whereKey:@"receiverUsername" equalTo:[PFUser currentUser].username];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error && objects && objects.count != 0) {
            dataSource = [objects mutableCopy];
            [self.tableView reloadData];
        }
    }];
}

#pragma mark - uitableview 

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (section == 0) {
        return dataSource?dataSource.count:1;
    }else{
        return 1;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.section == 0) {
        //no friend request
        if (!dataSource || dataSource.count == 0) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"noRequestCell" forIndexPath:indexPath];
            return cell;
        }else{
            
            FriendQuestTableViewCell *cell = (FriendQuestTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"friendRequestCell" forIndexPath:indexPath];
            cell.delegate = self;
            //set avatar
            [Helper getAvatarForUser:[dataSource[indexPath.row] objectForKey:@"senderUsername"] avatarType:AvatarTypeMid forImageView:cell.profileImageView];
            //set sender username
            cell.usernameLabel.text = [dataSource[indexPath.row] objectForKey:@"senderUsername"];
            return cell;
        }
    }else{
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"fakeCell" forIndexPath:indexPath];
        return cell;
    }
    
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if(section == 0){
        return @"Follow Request";
    }else{
        return @"Notification";
    }
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.section == 0){
        
        if (!dataSource || dataSource.count == 0) {
            return 47;
        }else{
            return 84;
        }
        
    }else{
        return 44;
    }
    
}

#pragma mark - FriendQuestTableViewCellDelegate

-(void)friendQuestTBCellAcceptButtonTappedWithCell:(FriendQuestTableViewCell *)cell{
    NSIndexPath *path = [self.tableView indexPathForCell:cell];
    PFObject *object = (PFObject *)dataSource[path.row];
    [object setObject:[NSNumber numberWithInt:1] forKey:@"requestStatus"];
    [object saveInBackground];

    //add quest sender to my "usersICanMessage" array
    [[PFUser currentUser] addUniqueObject:object[@"senderUsername"] forKey:UsersIAllowToFollowMe];
    [[PFUser currentUser] saveInBackground];
    
    NSDictionary *dict = @{@"senderUsername":object[@"senderUsername"],
                           @"receiverUsername":object[@"receiverUsername"]};
    [PFCloud callFunctionInBackground:@"addToFollowers" withParameters:dict block:^(id object, NSError *error) {
        if (error) {
            [FPLogger record:[NSString stringWithFormat:@"add to followers failed with error: %@",error]];
            NSLog(@"add to followers failed with error: %@",error);
        }else{
            NSIndexPath *path = [self.tableView indexPathForCell:cell];
            [dataSource removeObjectAtIndex:path.row];
            [self.tableView deleteRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationAutomatic];
            //show the "No New Follow Request Cell"
            if (dataSource.count == 0) {
                dataSource = nil;
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }
    }];
    //here in cloud code, we should add [PFUser currentUser].username to sender's followers
}

-(void)friendQuestTBCellNotNowButtonTappedWithCell:(FriendQuestTableViewCell *)cell{
    NSIndexPath *path = [self.tableView indexPathForCell:cell];
    PFObject *object = (PFObject *)dataSource[path.row];
    [object setObject:[NSNumber numberWithInt:3] forKey:@"requestStatus"];
    [object saveInBackground];
}

-(void)friendQuestTBCellDeclineButtonTappedWithCell:(FriendQuestTableViewCell *)cell{
    NSIndexPath *path = [self.tableView indexPathForCell:cell];
    PFObject *object = (PFObject *)dataSource[path.row];
    [object setObject:[NSNumber numberWithInt:2] forKey:@"requestStatus"];
    [object saveInBackground];
}

@end
