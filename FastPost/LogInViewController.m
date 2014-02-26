//
//  ViewController.m
//  FastPost
//
//  Created by Huang, Jason on 11/25/13.
//  Copyright (c) 2013 Huang, Jason. All rights reserved.
//

#import "LogInViewController.h"
#import <Parse/Parse.h>
#import "StatusTableViewController.h"
#import "SignUpViewController.h"
@interface LogInViewController ()

@end

@implementation LogInViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.activityIndicator.hidden = YES;
    self.title = @"dwndlr";
    //check if its first time user.
    //store userId in NSUserDefaults, hit the api and see if this userId is valid
    PFUser *user = [PFUser currentUser];
    if (user && user.isAuthenticated) {
        [self showStatusTableView];
    }
    
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.backBarButtonItem = nil;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    PFUser *user = [PFUser currentUser];
    if (user && user.isAuthenticated) {
        [self dismissViewControllerAnimated:NO completion:nil];
//        [self performSegueWithIdentifier:@"toStatusView" sender:self];
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)facebookButtonTapped:(id)sender {
    NSArray *permissions = [NSArray arrayWithObjects:@"email",@"read_friendlists", nil];
    [PFFacebookUtils logInWithPermissions:permissions block:^(PFUser *user, NSError *error) {
        if (!user) {
            NSLog(@"Uh oh. The user cancelled the Facebook login.");
        } else if (user.isNew) {
            NSLog(@"User signed up and logged in through Facebook!");
        } else {
            NSLog(@"User logged in through Facebook!");
            
            // When your user logs in, immediately get and store its Facebook ID, which is private, so need to do a separate query using FB SDK
            if (user) {
                [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                    if (!error) {
                        // Store the current user's Facebook ID on the user
                        [[PFUser currentUser] setObject:[result objectForKey:@"id"]
                                                 forKey:@"fbId"];
                        [[PFUser currentUser] saveInBackground];
                        
                        if (![PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
                            [PFFacebookUtils linkUser:[PFUser currentUser] permissions:nil block:^(BOOL succeeded, NSError *error) {
                                if (succeeded) {
                                    NSLog(@"Woohoo, user linked with Facebook!");
                                }else{
                                    NSLog(@"failed to link user with Facebook!");
                                }
                            }];
                        }
                       [self showStatusTableView];
                    }
                }];
            }
            
        }
    }];
}

- (IBAction)logInButtonTapped:(id)sender {
    
    [self.view endEditing:YES];
//    [self animateMoveViewDown];
    
    if (![[self.emailOrUsernameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""] &&
        ![[self.passwordTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]) {
        
        //spinner starts spinning
        self.activityIndicator.hidden = NO;
        [self.activityIndicator startAnimating];
        
        //hit api and store user info
        if ([self.emailOrUsernameTextField.text rangeOfString:@"@"].location == NSNotFound) {
            
            //username to log in
            [PFUser logInWithUsernameInBackground:self.emailOrUsernameTextField.text password:self.passwordTextField.text block:^(PFUser *user, NSError *error) {
                if (!error) {
                    [self showStatusTableView];
                }else{
                    [self showIncorrectPasswordOrFieldWithName:@"username"];
                }
                
                [self.activityIndicator stopAnimating];
            }];
        }else{
            //email to log in
            PFQuery *query = [PFQuery queryWithClassName:[PFUser parseClassName]];
            [query whereKey:@"email" equalTo:self.emailOrUsernameTextField.text];
            [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                if (!error && object) {
                    [PFUser logInWithUsernameInBackground:object[@"username"] password:self.passwordTextField.text block:^(PFUser *user, NSError *error) {
                        if (!error) {
                            [self showStatusTableView];
                        }else{
                            [self showIncorrectPasswordOrFieldWithName:@"email"];
                        }
                    }];

                }else{
                    [self showIncorrectPasswordOrFieldWithName:@"email"];
                }
                
                [self.activityIndicator stopAnimating];
            }];
        }

    }else{
        //invalid input
        //pop up alert
    }
}

-(void)showIncorrectPasswordOrFieldWithName:(NSString *)wrongFieldName{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:@"Incorrect %@ or password, please retry",wrongFieldName] delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
    [alert show];
    
}

- (IBAction)signUpButtonTapped:(id)sender {
    
    SignUpViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"signUpVC"];
    vc.loginVC = self;
    [self presentViewController:vc animated:YES completion:nil];

}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{

}

#pragma mark - ui text field delegate

//-(void)animateMoveViewUp{
//    
//    if (self.view.frame.origin.y < 0) {
//        return;
//    }
//    
//    [UIView animateWithDuration:.3 animations:^{
//        self.view.frame = CGRectMake(self.view.frame.origin.x,
//                                     self.view.frame.origin.y - 50,
//                                     self.view.frame.size.width,
//                                     self.view.frame.size.height);
//    }];
//}

//-(void)animateMoveViewDown{
//    
//    if(self.view.frame.origin.y == 0){
//        return;
//    }
//    
//    [UIView animateWithDuration:.3 animations:^{
//        self.view.frame = CGRectMake(self.view.frame.origin.x,
//                                     0,
//                                     self.view.frame.size.width,
//                                     self.view.frame.size.height);
//    }];
//}

//-(void)textFieldDidBeginEditing:(UITextField *)textField{
//    [self animateMoveViewUp];
//}


-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    
    if (textField == self.emailOrUsernameTextField) {
        textField.text = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [self.passwordTextField becomeFirstResponder];
    }else if(textField == self.passwordTextField){
//        [self animateMoveViewDown];
        textField.text = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [textField resignFirstResponder];
    }
    
    return NO;
}

-(void)showStatusTableView{
    [self dismissViewControllerAnimated:YES completion:nil];
//    [self performSegueWithIdentifier:@"toStatus" sender:self];
//    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
//    StatusTableViewController *vc = (StatusTableViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"statusView"];
//    
//    NSMutableArray *viewControllers = [NSMutableArray arrayWithArray:[self.navigationController viewControllers]];
//    [viewControllers replaceObjectAtIndex:viewControllers.count-1 withObject:vc];
//    [self.navigationController setViewControllers:viewControllers animated:NO];
}

#pragma mark - FB SDK code to find friends

/*
 Then, when you are ready to search for your user's friends, you would issue another request:
 
 // Issue a Facebook Graph API request to get your user's friend list
 [FBRequestConnection startForMyFriendsWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
 if (!error) {
 // result will contain an array with your user's friends in the "data" key
 NSArray *friendObjects = [result objectForKey:@"data"];
 NSMutableArray *friendIds = [NSMutableArray arrayWithCapacity:friendObjects.count];
 // Create a list of friends' Facebook IDs
 for (NSDictionary *friendObject in friendObjects) {
 [friendIds addObject:[friendObject objectForKey:@"id"]];
 }
 
 // Construct a PFUser query that will find friends whose facebook ids
 // are contained in the current user's friend list.
 PFQuery *friendQuery = [PFUser query];
 [friendQuery whereKey:@"fbId" containedIn:friendIds];
 
 // findObjects will return a list of PFUsers that are friends
 // with the current user
 NSArray *friendUsers = [friendQuery findObjects];
 }
 }];
 */

//// Fetch user data
//[FBRequestConnection
// startForMeWithCompletionHandler:^(FBRequestConnection *connection,
//                                   id<FBGraphUser> user,
//                                   NSError *error) {
//     if (!error) {
//         NSString *userInfo = @"";
//         
//         // Example: typed access (name)
//         // - no special permissions required
//         userInfo = [userInfo
//                     stringByAppendingString:
//                     [NSString stringWithFormat:@"Name: %@\n\n",
//                      user.name]];
//         
//         // Example: typed access, (birthday)
//         // - requires user_birthday permission
//         userInfo = [userInfo
//                     stringByAppendingString:
//                     [NSString stringWithFormat:@"Birthday: %@\n\n",
//                      user.birthday]];
//         
//         // Example: partially typed access, to location field,
//         // name key (location)
//         // - requires user_location permission
//         userInfo = [userInfo
//                     stringByAppendingString:
//                     [NSString stringWithFormat:@"Location: %@\n\n",
//                      user.location[@"name"]]];
//         
//         // Example: access via key (locale)
//         // - no special permissions required
//         userInfo = [userInfo
//                     stringByAppendingString:
//                     [NSString stringWithFormat:@"Locale: %@\n\n",
//                      user[@"locale"]]];
//         
//         // Example: access via key for array (languages)
//         // - requires user_likes permission
//         if (user[@"languages"]) {
//             NSArray *languages = user[@"languages"];
//             NSMutableArray *languageNames = [[NSMutableArray alloc] init];
//             for (int i = 0; i < [languages count]; i++) {
//                 languageNames[i] = languages[i][@"name"];
//             }
//             userInfo = [userInfo
//                         stringByAppendingString:
//                         [NSString stringWithFormat:@"Languages: %@\n\n",
//                          languageNames]];
//         }
//         
//         // Display the user info
//         self.userInfoTextView.text = userInfo;
//     }   
// }];
@end
