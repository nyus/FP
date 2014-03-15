//
//  StatusTableViewHeaderViewController.m
//  FastPost
//
//  Created by Huang, Sihang on 12/4/13.
//  Copyright (c) 2013 Huang, Sihang. All rights reserved.
//

#import "StatusTableViewHeaderViewController.h"

@interface StatusTableViewHeaderViewController ()

@end

@implementation StatusTableViewHeaderViewController

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
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)addFriendButtonTapped:(id)sender {
    [self.delegate tbHeaderAddFriendButtonTapped];
}

- (IBAction)composeButtonTapped:(id)sender {
    [self.delegate tbHeaderComposeNewStatusButtonTapped];
}

- (IBAction)settingButtonTapped:(id)sender {
    [self.delegate tbHeaderSettingButtonTapped];
}

@end
