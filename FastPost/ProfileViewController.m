//
//  ProfileViewController.m
//  FastPost
//
//  Created by Sihang Huang on 1/7/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "ProfileViewController.h"
#import "StatusTableViewCell.h"
#import <Parse/Parse.h>
@interface ProfileViewController ()

@end

@implementation ProfileViewController

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
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)displayUserInfo{
    self.userNameLabel.text = [PFUser currentUser].username;
}

-(void)displayUserSocialInfo{

}

-(void)displayUserActivity{}

- (IBAction)avatarImageViewTapped:(id)sender {
    
}

#pragma mark - UITableViewDelete 

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;

}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    StatusTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    return cell;
}
@end
