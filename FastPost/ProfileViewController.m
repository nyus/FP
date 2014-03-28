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
//#import "StatusTableViewHeaderViewController.h"
#define BACKGROUND_CELL_HEIGHT 300.0f
#define ORIGIN_Y_CELL_MESSAGE_LABEL 86.0f

@interface ProfileViewController ()<UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>{
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
    
    if([self.presentingSource isEqualToString:@"statusViewController"]){
        self.editButton.hidden = YES;
    }else{
        self.followButton.hidden = YES;
    }
    
    //if yes, table view cell will make room for like, comment and revive buttons
    self.needSocialButtons = NO;
}

-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    
////STORE POSTS THE SELF SENDS LOCALLY SO TAHT WE CAN PULL PREVIOUS POSTS INSTANTLY AND ALSO SAVE RESOURCES. WHEN THIS TAB SHOWS, FIRST CHECK IF THERE IS ANY POST LOCALLY, IF NOT, CHECK IF THIS USER EXISTS IN OUR DATABASE, IF SO, PULL OLD STATUSES FROM PARSE AND STORE THEM LOCALLY
//    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Status"];
//    NSSortDescriptor *des = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
//    request.sortDescriptors = @[des];
//    NSError *error;
//    NSArray *results = [[SharedDataManager sharedInstance].managedObjectContext executeFetchRequest:request error:&error];
//    //if no status has been stored, two possibilities:
//    //1. this is a new user
//    //2. this is a returning user
//    if (results.count == 0) {
//        
//    }else{
//        //display result
//    }
    
//need to do something here. dont grab everything when user comes back to this tab
    [self fetchNewStatusWithCount:25 remainingTime:nil];
//this method needs rework
    [self updateUserInfoValues];
}

-(void)fetchNewStatusWithCount:(int)count remainingTime:(NSNumber *)remainingTimeInSec{
    
    PFQuery *query = [PFQuery queryWithClassName:@"Status"];
    query.limit = count;
    [query orderByDescending:@"createdAt"];
    [query whereKey:@"posterUsername" equalTo:[PFUser currentUser].username];
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
    self.userNameLabel.text = [PFUser currentUser].username;
    
    //set avatar
    [Helper getAvatarForSelfOnImageView:self.avatarImageView];
    
    //# of dwindles.
    //first try to pull from user default, and when a user posts a new status, increase this user default value. for first time user, this will work but for existing users, need to pull from parse to get the # of posts already out there
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *numberPosts = [defaults objectForKey:@"numberofposts"];
    if (numberPosts) {
        self.dwindleLabel.text = numberPosts.stringValue;
    }else{
        PFQuery *query = [[PFQuery alloc] initWithClassName:@"Status"];
        [query whereKey:@"posterUsername" equalTo:[PFUser currentUser].username];
        [query countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
            self.dwindleLabel.text = [NSString stringWithFormat:@"%d", number];
            [defaults setObject:[NSNumber numberWithInt:number] forKey:@"numberofposts"];
            [defaults synchronize];
        }];
    }
    
    
    //set following. # of following is the count of friends minus one(since user is friend of himself)
    PFUser *me = [PFUser currentUser];
    if (me[@"usersIFollow"] != [NSNull null]) {
        self.followingLabel.text = [NSString stringWithFormat:@"%d",(int)[me[@"usersIFollow"] count]-1];
    }else{
        self.followingLabel.text = [NSString stringWithFormat:@"%d",0];
    }
    
    //set follower.
    if (me[@"followers"] != [NSNull null]) {
        self.followerLabel.text = [NSString stringWithFormat:@"%d",(int)[me[@"followers"] count]];
    }else{
        self.followerLabel.text = [NSString stringWithFormat:@"%d",0];
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)avatarImageViewTapped:(id)sender {
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
        
        [self presentViewController:imagePicker animated:YES completion:nil];
        
    }else if(buttonIndex == 1){
        // this is for a bug when you first add from gallery, then take a photo, the picker view controller shifts down
        if (imagePicker == nil) {
            imagePicker = [[UIImagePickerController alloc] init];
        }
        imagePicker.delegate = self;
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
}

#pragma mark - image picker delegates

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *chosenImage = [info objectForKey:UIImagePickerControllerOriginalImage];
  
//    // If photot did not come from photo album, add photo to our custom album and the regular camera roll
//    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
//        [self saveImageToAlbum:image];
//    } else {
//        //If photo came from regular album, add to custom album only
//        [self saveImageFromAssetURL:[info objectForKey:@"UIImagePickerControllerReferenceURL"]];
//    }
    
    //save
//    NSError *error;
//    [[SharedDataManager sharedInstance].managedObjectContext save:&error];
    
    //save to parse
    
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
    [Helper saveAvatar:data forUser:[PFUser currentUser].username];
    
    [picker dismissViewControllerAnimated:YES completion:^{
        self.avatarImageView.image = chosenImage;
    }];
}

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

@end
