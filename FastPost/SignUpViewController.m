//
//  SignUpViewController.m
//  FastPost
//
//  Created by Sihang Huang on 2/24/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "SignUpViewController.h"
#import <Parse/Parse.h>
#import "LogInViewController.h"
@interface SignUpViewController ()<UIAlertViewDelegate>{
    UIAlertView *signUpSuccessAlert;
}

@end

@implementation SignUpViewController

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
    self.activityIndicator.hidden = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)showStatusTableView{
    [signUpSuccessAlert dismissWithClickedButtonIndex:0 animated:YES];
    [self dismissViewControllerAnimated:NO completion:^{
        [self.loginVC dismissViewControllerAnimated:NO completion:nil];
    }];
}

- (IBAction)signUpButtonTapped:(id)sender {
    
    if (![[self.emailTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""] &&
        ![[self.usernameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""] &&
        ![[self.passwordTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]) {

        //spinner starts spinning
        self.activityIndicator.hidden = NO;
        [self.activityIndicator startAnimating];

        //hit api and store user info
        PFUser *newUser = [PFUser user];
        [PFUser enableAutomaticUser];
        newUser.email = self.emailTextField.text;
        if (![self.usernameTextField.text isEqualToString:@""]) {
            newUser.username = self.usernameTextField.text;
        }
        newUser.password = self.passwordTextField.text;
        [newUser signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            [self.activityIndicator stopAnimating];

            if(succeeded){

                //
                [PFUser logInWithUsername:self.usernameTextField.text password:self.passwordTextField.text];
                [[PFUser currentUser] addObject:[PFUser currentUser].username forKey:@"friends"];
                [[PFUser currentUser] saveInBackground];
                
                //set user on PFInstallation object so that we can send out targeted pushes
                [[PFInstallation currentInstallation] setObject:[PFUser currentUser] forKey:@"user"];
                [[PFInstallation currentInstallation] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (succeeded) {
                        NSLog(@"successfully set PFUser on PFInstallation");
                    }
                }];
                
                signUpSuccessAlert = [[UIAlertView alloc] initWithTitle:nil message:@"Congrats! You have successfully signed up!" delegate:self cancelButtonTitle:nil otherButtonTitles:nil, nil];
                signUpSuccessAlert.tag = 0;
                [signUpSuccessAlert show];
                [self performSelector:@selector(showStatusTableView) withObject:nil afterDelay:.5];
            }else{

                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Sign up failed. Please try again" delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
                alert.tag = 1;
                [alert show];
                
            }
            
            [self.activityIndicator stopAnimating];
        }];
    }
}

- (IBAction)backToLoginButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    
    if (textField == self.emailTextField) {
        textField.text = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [self.usernameTextField becomeFirstResponder];
    }else if (textField == self.usernameTextField){
        textField.text = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [self.passwordTextField becomeFirstResponder];
    }
    else if(textField == self.passwordTextField){
        [self animateMoveViewUp];
        textField.text = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [textField resignFirstResponder];
    }
    
    return NO;
}

-(void)animateMoveViewUp{
    
    if (self.view.frame.origin.y < 0) {
        return;
    }
    
    [UIView animateWithDuration:.3 animations:^{
        self.view.frame = CGRectMake(self.view.frame.origin.x,
                                     self.view.frame.origin.y - 50,
                                     self.view.frame.size.width,
                                     self.view.frame.size.height);
    }];
}

#pragma mark UIAlertViewDelegate

//-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
//    //successfully signed up
//    if (alertView.tag == 0) {
//        [self showStatusTableView];
//    }
//}
@end
