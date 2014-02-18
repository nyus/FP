//
//  FriendQuestViewController.m
//  FastPost
//
//  Created by Huang, Jason on 2/14/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "FriendQuestViewController.h"
#import <Parse/Parse.h>
@interface FriendQuestViewController ()<UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate>

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

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 10;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    return cell;
}

-(void)removeSelfFromParent{
    [UIView animateWithDuration:.3 animations:^{
        self.blurToolBar.alpha = 0.0f;
        self.view.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
    }];
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
            
            //add the person that user wants to follow in user's friends array on server
            PFUser *foundUser = (PFUser *)object;
            
#warning cant modify other PFUser objects, need to do it on the cloud
            
            //add self to the person that self follows to person's follower array on server
            //                [foundUser addObject:[PFUser currentUser].username forKey:@"follower"];
            [foundUser setObject:@"username" forKey:@"test"];
            [foundUser saveInBackground];
            
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
@end

