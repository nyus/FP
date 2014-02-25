//
//  ViewController.h
//  FastPost
//
//  Created by Huang, Jason on 11/25/13.
//  Copyright (c) 2013 Huang, Jason. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LogInViewController : UIViewController<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *emailOrUsernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
- (IBAction)facebookButtonTapped:(id)sender;
- (IBAction)logInButtonTapped:(id)sender;
- (IBAction)signUpButtonTapped:(id)sender;
@end
