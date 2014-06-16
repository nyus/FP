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
#import "FPLogger.h"
@interface FriendQuestViewController ()<UITextFieldDelegate,FriendQuestTableViewCellDelegate>{
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

}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    
    
    if ([self.textField.text.lowercaseString isEqualToString:[PFUser currentUser].username]) {
        return;
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
                    
                    self.textField.text = nil;
                    [self removeSelfFromParent];
                    [self.textField resignFirstResponder];
                    
                    [Helper sendFriendRequestTo:((PFUser *)object).username from:[PFUser currentUser].username];
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

@end

