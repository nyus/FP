//
//  ProfileViewController.m
//  FastPost
//
//  Created by Sihang Huang on 1/7/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "ProfileViewController.h"
#import "StatusTableViewCell.h"
#import <Parse/Parse.h>
#import "Status.h"
#import "Helper.h"
#import <CoreData/CoreData.h>
#import "SharedDataManager.h"
#import "FPLogger.h"
#import "ELCImagePickerController.h"
#import "ELCAlbumPickerController.h"
#import "ELCAssetTablePicker.h"
//#import "StatusTableViewHeaderViewController.h"
#define BACKGROUND_CELL_HEIGHT 300.0f
#define ORIGIN_Y_CELL_MESSAGE_LABEL 86.0f
#define TB_HEADER_HEIGHT 20.0f
@interface ProfileViewController ()<UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate,ELCImagePickerControllerDelegate>{
    UIImagePickerController *imagePicker;
//    StatusTableViewHeaderViewController *headerViewVC;
}
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
    //this is initialization when the profile page is first loaded
    if(self.userNameOfUserProfileToDisplay == nil){
        self.userNameOfUserProfileToDisplay = [PFUser currentUser].username;
    }
    
    if([self.userNameOfUserProfileToDisplay isEqualToString:[PFUser currentUser].username]){
        self.followButton.hidden = YES;
        self.fakeNavigationBar.hidden = YES;
        //disable interaction with the avatar imageviews
        self.leftAvatarImageView.userInteractionEnabled = YES;
        self.avatarImageView.userInteractionEnabled = YES;
        self.rightAvatarImageView.userInteractionEnabled = YES;
    }else{
        self.followButton.hidden = NO;
        self.fakeNavigationBar.hidden = NO;
        self.userNameLabelTopSpaceToTopLayoutConstraint.constant = 49;
        //other users cannot see my followers and following
        self.followerLabel.hidden = YES;
        self.followersTitleLabel.hidden= YES;
        self.followingLabel.hidden = YES;
        self.followingTitleLabel.hidden = YES;
        //disable interaction with the avatar imageviews
        self.leftAvatarImageView.userInteractionEnabled = NO;
        self.avatarImageView.userInteractionEnabled = NO;
        self.rightAvatarImageView.userInteractionEnabled = NO;
    }
}

-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    
//need to do something here. dont grab everything when user comes back to this tab
    [self fetchNewStatusWithCount:25 remainingTime:nil];
//this method needs rework
    [self updateUserInfoValues];
}

-(void)fetchNewStatusWithCount:(int)count remainingTime:(NSNumber *)remainingTimeInSec{
    
    PFQuery *query = [PFQuery queryWithClassName:@"Status"];
    query.limit = count;
    [query orderByDescending:@"createdAt"];
    [query whereKey:@"posterUsername" equalTo:self.userNameOfUserProfileToDisplay];
    [query whereKey:@"expirationDate" greaterThan:[NSDate date]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if (objects.count != 0) {
            
            if (self.dataSource.count > 0) {
                [self.dataSource removeAllObjects];
                
                for (int i = 0 ; i<objects.count; i++) {
                    Status *newStatus = [[Status alloc] initWithPFObject:objects[i]];
                    if (!self.dataSource) {
                        self.dataSource = [NSMutableArray array];
                    }
                    [self.dataSource addObject:newStatus];
                }
                
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
            }else{
                for (PFObject *status in objects) {
                    Status *newStatus = [[Status alloc] initWithPFObject:status];
                    if (!self.dataSource) {
                        self.dataSource = [NSMutableArray array];
                    }
                    [self.dataSource addObject:newStatus];
                }
                [self.tableView reloadData];
            }
        }else{
            //
            NSLog(@"0 items fetched from parse");
        }
        
    }];
}


-(void)updateUserInfoValues{
    
    //name
    self.userNameLabel.text = self.userNameOfUserProfileToDisplay;
    
    //# of dwindles.
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    //pull from defaults for faster loading # dwindles, followers and following
    if ([self.userNameOfUserProfileToDisplay isEqualToString:[PFUser currentUser].username]) {
        NSNumber *hasDoneInitialStatusCount = [defaults objectForKey:@"hasDoneInitialStatusCount"];
        if (hasDoneInitialStatusCount.boolValue == YES) {
            NSNumber *numberPosts = [defaults objectForKey:@"numberofposts"];
            self.dwindleLabel.text = numberPosts.stringValue;
        }
        
        NSString *numOfFollowing = [defaults objectForKey:@"numOfFollowing"];
        if (numOfFollowing != nil) {
            [FPLogger record:[NSString stringWithFormat:@"load number of following:%@ from user default",self.followingLabel.text]];
            self.followingLabel.text = numOfFollowing;
        }
        NSString *numOfFollowers = [defaults objectForKey:@"numOfFollowers"];
        if (numOfFollowing != nil) {
            [FPLogger record:[NSString stringWithFormat:@"load number of followers:%@ from user default",self.followerLabel.text]];
            self.followerLabel.text = numOfFollowers;
        }
        
    }
    //set avatar
    BOOL isLocalAvatarExisted = YES;
    NSArray *avatars = [Helper getAvatarsForSelf];
    if (avatars.count == 0) {
        isLocalAvatarExisted = NO;
    }else{
        [self positionAvatarImageViewsWithAvatars:avatars];
    }
    
    //update this value
    PFQuery *query = [[PFQuery alloc] initWithClassName:@"Status"];
    [query whereKey:@"posterUsername" equalTo:self.userNameOfUserProfileToDisplay];
    [query countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        self.dwindleLabel.text = [NSString stringWithFormat:@"%d", number];
        
        if ([self.userNameOfUserProfileToDisplay isEqualToString:[PFUser currentUser].username]) {
            [defaults setObject:[NSNumber numberWithInt:number] forKey:@"numberofposts"];
            [defaults setBool:YES forKey:@"hasDoneInitialStatusCount"];
            [defaults synchronize];
        }
    }];

    //only my profile needs to show # of followers and following
    if ([self.userNameOfUserProfileToDisplay isEqualToString:[PFUser currentUser].username]) {
        //set following. # of following is the count of friends minus one(since user is friend of himself)
        [[PFUser currentUser] refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            
            PFUser *me = (PFUser *)object;
            if (me[UsersAllowMeToFollow] != [NSNull null]) {
                self.followingLabel.text = [NSString stringWithFormat:@"%d",(int)[me[UsersAllowMeToFollow] count]];
            }else{
                self.followingLabel.text = [NSString stringWithFormat:@"%d",0];
            }
            
            //set follower.
            if (me[UsersIAllowToFollowMe] != [NSNull null]) {
                self.followerLabel.text = [NSString stringWithFormat:@"%d",(int)[me[UsersIAllowToFollowMe] count]];
            }else{
                self.followerLabel.text = [NSString stringWithFormat:@"%d",0];
            }
            
            if (!isLocalAvatarExisted) {
                [Helper getServerAvatarForUser:me.username avatarType:AvatarTypeMid forImageView:self.avatarImageView];
            }
            
            [FPLogger record:[NSString stringWithFormat:@"load number of following:%@ and followers:%@ after refreshing current user obj",self.followingLabel.text,self.followerLabel.text]];
            
            [defaults setObject:self.followingLabel.text forKey:@"numOfFollowing"];
            [defaults setObject:self.followerLabel.text forKey:@"numOfFollowers"];
            [defaults synchronize];
        }];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)avatarImageViewTapped:(UIImageView *)sender {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Camera",@"Gallery", nil];
    [sheet showFromTabBar:self.tabBarController.tabBar];
}

#pragma mark - UIActionSheetDelegate 

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    //0 camera, 1 gallery, 2 cancel
    if(buttonIndex == 0){
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            // this is for a bug when you first add from gallery, then take a photo, the picker view controller shifts down
            if (imagePicker == nil) {
                imagePicker = [[UIImagePickerController alloc] init];
                imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
                imagePicker.allowsEditing = NO;
                imagePicker.cameraCaptureMode = (UIImagePickerControllerCameraCaptureModePhoto);
            }else {
                //make sure the source type is corret for cached UIImagePickerController
                imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
            }
            imagePicker.delegate = self;
        }
        
        [self presentViewController:imagePicker animated:YES completion:^{
            imagePicker = nil;
        }];
        
    }else if(buttonIndex == 1){
        
        ELCImagePickerController *elcPicker = [[ELCImagePickerController alloc] initImagePicker];
        elcPicker.maximumImagesCount = 3;
        elcPicker.returnsOriginalImage = NO; //Only return the fullScreenImage, not the fullResolutionImage
        elcPicker.imagePickerDelegate = self;
        
        [self presentViewController:elcPicker animated:YES completion:nil];
    }
}

#pragma mark - image picker delegates

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *chosenImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    //save to parse and local
    
    float scale = 0.0f;
    if (chosenImage.size.width > chosenImage.size.height) {
        scale = self.avatarImageView.frame.size.width/chosenImage.size.width;
    }else{
        scale = self.avatarImageView.frame.size.height/chosenImage.size.height;
    }
    //reason for scale*2. UIImageJPEGRepresentation's compressionQuality seems to be 2 times the value of scale
    //for example, if compressionQuality is 0.8, then the size would be appro 0.4 time of the original size
    NSData *data = UIImageJPEGRepresentation(chosenImage,scale);
    
    //save profile image to local and server
    [Helper saveAvatar:data avatarType:AvatarTypeMid forUser:[PFUser currentUser].username];
    
    [picker dismissViewControllerAnimated:YES completion:^{
        self.avatarImageView.image = chosenImage;
    }];
}

#pragma mark ELCImagePickerControllerDelegate Methods


-(void)positionAvatarImageViewsWithAvatars:(NSArray *)images{
    if (images.count == 1) {
        self.avatarImageView.image = images[0];
        self.avatarImageView.center = CGPointMake((int)self.avatarScrollview.frame.size.width/2, self.avatarImageView.center.y);
        self.leftAvatarImageView.hidden = YES;
        self.rightAvatarImageView.hidden = YES;
    }else if (images.count==2){
        self.leftAvatarImageView.image = images[0];
        self.avatarImageView.image = images[1];
        self.leftAvatarImageView.center = CGPointMake((int)self.avatarScrollview.frame.size.width/4, self.leftAvatarImageView.center.y);
        self.avatarImageView.center = CGPointMake((int)self.avatarScrollview.frame.size.width*3/4, self.avatarImageView.center.y);
        self.rightAvatarImageView.hidden = YES;
    }else if (images.count==3){
        self.leftAvatarImageView.image = images[0];
        self.avatarImageView.image = images[1];
        self.rightAvatarImageView.image = images[2];
        
        self.avatarImageView.center = CGPointMake((int)self.avatarImageView.frame.size.width/2, self.avatarImageView.center.y);
        self.leftAvatarImageView.center = CGPointMake((int)self.avatarScrollview.frame.size.width*3/2, self.leftAvatarImageView.center.y);
        self.rightAvatarImageView.center = CGPointMake((int)self.avatarScrollview.frame.size.width*5/2, self.rightAvatarImageView.center.y);
        
        self.avatarImageView.hidden=NO;
        self.leftAvatarImageView.hidden=NO;
        self.rightAvatarImageView.hidden=NO;
    }
}

-(void)scaleDownImagesAndSave:(NSArray *)imageArray{
    
    for (int i =0; i<imageArray.count; i++) {

        UIImage *chosenImage = imageArray[i];
        float scale = 0.0f;
        if (chosenImage.size.width > chosenImage.size.height) {
            scale = self.avatarImageView.frame.size.width/chosenImage.size.width;
        }else{
            scale = self.avatarImageView.frame.size.height/chosenImage.size.height;
        }
        //reason for scale*2. UIImageJPEGRepresentation's compressionQuality seems to be 2 times the value of scale
        //for example, if compressionQuality is 0.8, then the size would be appro 0.4 time of the original size
        NSData *data = UIImageJPEGRepresentation(chosenImage,scale);
        
        [Helper saveAvatar:data avatarType:i forUser:[PFUser currentUser].username];
    }
}

- (void)elcImagePickerController:(ELCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info
{
    
    
    NSMutableArray *array = [NSMutableArray array];
    for (NSDictionary *dict in info) {
        [array addObject:dict[@"UIImagePickerControllerOriginalImage"]];
    }
    [self scaleDownImagesAndSave:array];
    [self positionAvatarImageViewsWithAvatars:array];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)elcImagePickerControllerDidCancel:(ELCImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableView delegate

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return [super numberOfSectionsInTableView:tableView];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [super tableView:tableView numberOfRowsInSection:section];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    if (self.dataSource.count != 0 && section == 0) {
        UITableViewHeaderFooterView *view = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:@"header"];
        view.textLabel.text = @"Your live posts";
        return view;
    }
    
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return self.dataSource.count==0?0:TB_HEADER_HEIGHT;
}

- (IBAction)navigationBarBackButtonTapped:(id)sender {
    //self.navigationController is not self.fakeNavigationBar. self.navi
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)followButtonTapped:(id)sender {
    [Helper sendFriendRequestTo:self.userNameOfUserProfileToDisplay from:[PFUser currentUser].username];
}


@end
