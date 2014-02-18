//
//  FriendQuestViewController.m
//  FastPost
//
//  Created by Huang, Jason on 2/14/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "FriendQuestViewController.h"
#import "FriendQuestTableViewCell.h"
#import <Parse/Parse.h>
#import "Helper.h"
@interface FriendQuestViewController ()<UITableViewDataSource,UITableViewDelegate,FriendQuestTableViewCellDelegate>{
    NSArray *dataSource;
}

@end

@implementation FriendQuestViewController

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
    [self pullFriendRequest];
    
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
    [query whereKey:@"requestStatus" notEqualTo:[NSNumber numberWithInt:1]];
    [query whereKey:@"requestStatus" notEqualTo:[NSNumber numberWithInt:2]];
    [query whereKey:@"receiverUsername" equalTo:[PFUser currentUser].username];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error && objects && objects.count != 0) {
            dataSource = objects;
            [self.tableView reloadData];
        }
    }];
}

#pragma mark - Table View

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return dataSource?dataSource.count:1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    //no friend request
    if (!dataSource || dataSource.count == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"noRequestCell" forIndexPath:indexPath];
        return cell;
    }else{
        
        FriendQuestTableViewCell *cell = (FriendQuestTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
        cell.delegate = self;
        //set avatar
        [Helper getAvatarForUser:[dataSource[indexPath.row] objectForKey:@"senderUsername"] forImageView:cell.profileImageView];
        //set sender username
        cell.usernameLabel.text = [dataSource[indexPath.row] objectForKey:@"senderUsername"];
        return cell;
    }
}
- (IBAction)cancelButtonTapped:(id)sender {
    [self.view removeFromSuperview];
}

#pragma mark - FriendQuestTableViewCellDelegate

-(void)friendQuestTBCellAcceptButtonTappedWithCell:(FriendQuestTableViewCell *)cell{
    NSIndexPath *path = [self.tableView indexPathForCell:cell];
    PFObject *object = (PFObject *)dataSource[path.row];
    [object setObject:[NSNumber numberWithInt:1] forKey:@"requestStatus"];
    [object saveInBackground];
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

