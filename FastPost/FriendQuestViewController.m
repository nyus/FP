//
//  FriendQuestViewController.m
//  FastPost
//
//  Created by Huang, Sihang on 2/14/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
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
  
    //KVO on view.alpha. everytime alpha goes to 1, need to pull to see if there is new friend
    [self.view addObserver:self forKeyPath:@"alpha" options:NSKeyValueObservingOptionNew context:NULL];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self pullFriendRequest];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - KVO

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([keyPath isEqualToString:@"alpha"] && self.view.alpha == 1.0f) {
        [self pullFriendRequest];
    }
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
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"This user doesn't exist." delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
            [alert show];
            self.textField.text = nil;
        }else{
            
            //if such request already existed, dont do it again
            PFQuery *query = [[PFQuery alloc] initWithClassName:@"FriendRequest"];
            [query whereKey:@"senderUsername" equalTo:[PFUser currentUser].username];
            [query whereKey:@"receiverUsername" equalTo:((PFUser *)object).username];
            [query getFirstObjectInBackgroundWithBlock:^(PFObject *result, NSError *error) {
                if (!error && result) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"You have already sent a request to this user." delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
                    [alert show];
                    self.textField.text = nil;
                }else{
                    
                    //create a new FriendRequest object and send it to parse
                    PFObject *request = [[PFObject alloc] initWithClassName:@"FriendRequest"];
                    request[@"senderUsername"] = [PFUser currentUser].username;
                    request[@"receiverUsername"] = ((PFUser *)object).username;
                    //FriendRequest.requestStatus
                    //1. accepted 2. denied 3. not now 4. new request
                    request[@"requestStatus"] = [NSNumber numberWithInt:4];
                    [request saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        if (succeeded) {
                            self.textField.text = nil;
                            [self removeSelfFromParent];
                            [self.textField resignFirstResponder];
                            
                            //send out push notification to Friend Requrest receiver
                            //first query the PFUser(recipient) with the specific username
                            PFQuery *innerQuery = [PFQuery queryWithClassName:[PFUser parseClassName]];
                            [innerQuery whereKey:@"username" equalTo:((PFUser *)object).username];
                            //then query this PFuser set on PFInstallation
                            PFQuery *query = [PFInstallation query];
                            [query whereKey:@"user" matchesQuery:innerQuery];
                            
                            PFPush *push = [[PFPush alloc] init];
                            [push setQuery:query];
                            [push setMessage:[NSString stringWithFormat:@"%@ has sent you a follow request",[PFUser currentUser].username]];
                            [push sendPushInBackground];
                            
                            NSLog(@"request %@ sent",request);
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Request sent!" delegate:self cancelButtonTitle:@"Done" otherButtonTitles:nil, nil];
                            [alert show];
                        }else{
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Something went wrong, please try again." delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
                            [alert show];
                        }
                    }];
                }
            }];
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

    NSDictionary *dict = @{@"senderUsername":object[@"senderUsername"],
                           @"receiverUsername":object[@"receiverUsername"]};
    [PFCloud callFunctionInBackground:@"addToFollowers" withParameters:dict block:^(id object, NSError *error) {
        if (error) {
            NSLog(@"add to followers failed with error: %@",error);
        }else{
            [self.tableView deleteRowsAtIndexPaths:@[[self.tableView indexPathForCell:cell]] withRowAnimation:UITableViewRowAnimationAutomatic];
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
- (IBAction)findButtonTapped:(id)sender {
    
}
@end

