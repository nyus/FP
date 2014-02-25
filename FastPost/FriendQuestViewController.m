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
@interface FriendQuestViewController ()<UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate,FriendQuestTableViewCellDelegate>{
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
    self.textField.returnKeyType = UIReturnKeySearch;
    self.containerView.layer.borderWidth = 0.5f;
    self.containerView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.containerView.layer.cornerRadius = 3.0f;
    
    //insert a toolbar behind to create the blur effect
    UIToolbar *blurEffectToolBar = [[UIToolbar alloc] initWithFrame:self.containerView.frame];
    blurEffectToolBar.barStyle = UIBarStyleDefault;
    //set a reference so that can remove it
    self.blurToolBar = blurEffectToolBar;
    [self.view insertSubview:blurEffectToolBar belowSubview:self.containerView];

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

-(void)removeSelfFromParent{
//    [UIView animateWithDuration:.3 animations:^{
//        self.blurToolBar.alpha = 0.0f;
        self.view.alpha = 0.0f;
//    } completion:^(BOOL finished) {
        self.isOnScreen = NO;
//        [self.view removeFromSuperview];
//    }];
}

- (void)searchForFriend {
    
    if([self.textField.text isEqualToString:@""] ||
       [[self.textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]){
        return;
    }
    
    //find button hit
    NSString *key = nil;
    if ([self.textField.text rangeOfString:@"@"].location == NSNotFound) {
        key = @"username";
    }else{
        key = @"email";
    }
    PFQuery *queryExist = [PFQuery queryWithClassName:[PFUser parseClassName]];
    [queryExist whereKey:key equalTo:self.textField.text];
    [queryExist getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        //this user doenst exist
        if (!object) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"This user doesn't exist" delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
            [alert show];
        }else{
            
            //create a new FriendRequest object and send it to parse
            PFObject *object = [[PFObject alloc] initWithClassName:@"FriendRequest"];
            object[@"senderUsername"] = [PFUser currentUser].username;
            object[@"receiverUsername"] = ((PFUser *)object).username;
            //FriendRequest.requestStatus
            //1. accepted 2. denied 3. not now 4. new request
            object[@"requestStatus"] = [NSNumber numberWithInt:4];
            [object saveInBackground];
#warning cant modify other PFUser objects, need to do it on the cloud
#warning when the friend request is approved, save in cloud code.
            
            
            
            
            //                [[PFUser currentUser] addObject:foundUser.username forKey:@"friends"];
            //                [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            //                    if (!succeeded) {
            //                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:@"Failed to follow %@, please try again",foundUser.username] delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
            //                        [alert show];
            //                    }else{
            //                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:@"Success! You can now see posts from %@",foundUser.username] delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
            //                        [alert show];
            //                    }
            //                }];
        }
    }];

}

#pragma mark - UITextField

//return key changed to Search on keyboard
-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [self searchForFriend];
    return YES;
}

#pragma mark - FriendQuestTableViewCellDelegate

-(void)friendQuestTBCellAcceptButtonTappedWithCell:(FriendQuestTableViewCell *)cell{
    NSIndexPath *path = [self.tableView indexPathForCell:cell];
    PFObject *object = (PFObject *)dataSource[path.row];
    [object setObject:[NSNumber numberWithInt:1] forKey:@"requestStatus"];
    [object saveInBackground];

#warning cloud code here.
    NSDictionary *dict = @{@"senderUsername":object[@"senderUsername"],
                           @"receiverUsername":object[@"receiverUsername"]};
    [PFCloud callFunctionInBackground:@"addToFollowers" withParameters:dict block:^(id object, NSError *error) {
        
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
- (IBAction)findButtonTapped:(id)sender {
    
}
@end

