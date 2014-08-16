//
//  DetailedSocialNetworkTableViewController.m
//  FastPost
//
//  Created by Sihang on 8/13/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "DetailedSocialNetworkTableViewController.h"
#import <Parse/Parse.h>
#import "Helper.h"
#import "AvatarAndUsernameTableViewCell.h"
#import "ProfileViewController.h"
@interface DetailedSocialNetworkTableViewController (){
    NSMutableArray *dataSource;
}
@end

@implementation DetailedSocialNetworkTableViewController

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
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [self pullData];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}


-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
//    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)pullData{
    
    if (!dataSource) {
        dataSource = [NSMutableArray array];
    }
    
    PFQuery *query = [[PFQuery alloc] initWithClassName:[PFUser parseClassName]];
    [query whereKey:@"username" equalTo:self.userOfSocialNetwork];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!error && object) {
            if (self.isDisplayFollower) {
                for (NSString *username in object[@"usersIAllowToFollowMe"]) {
                    if(![username isEqualToString:self.userOfSocialNetwork]){
                        [dataSource addObject:username];
                    }
                }
            }else{
                for (NSString *username in object[@"usersAllowMeToFollow"]) {
                    if(![username isEqualToString:self.userOfSocialNetwork]){
                        [dataSource addObject:username];
                    }
                }
            }
        }else{
            dataSource = nil;
        }
        
        [self.tableView reloadData];
    }];
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
    if (!dataSource) {
        return 0;
    }else if (dataSource.count==0){
        //no follower, no following
        return 1;
    }else{
        return dataSource.count;
    }
    
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (dataSource.count==0) {
        if (self.isDisplayFollower) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"noFollower" forIndexPath:indexPath];
            return cell;
        }else{
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"noFollowing" forIndexPath:indexPath];
            return cell;
        }
    }else{
        AvatarAndUsernameTableViewCell *cell = (AvatarAndUsernameTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
        
        // Configure the cell...
        NSString *username = dataSource[indexPath.row];
        
        //first set default avatar
        [Helper getServerAvatarForUser:username avatarType:AvatarTypeMid isHighRes:NO completion:^(NSError *error, UIImage *image) {
            cell.avatarImageView.image = image;
        }];
        cell.usernameLabel.text = dataSource[indexPath.row];
        return cell;
    }
    
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"toUserProfile"]) {
        AvatarAndUsernameTableViewCell *cell = (AvatarAndUsernameTableViewCell *)sender;
        ProfileViewController *pVC = (ProfileViewController *)segue.destinationViewController;
        pVC.userNameOfUserProfileToDisplay = cell.usernameLabel.text;
    }
}
@end
