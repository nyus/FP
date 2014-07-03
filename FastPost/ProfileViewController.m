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
#import "ImageCollectionViewCell.h"
#import "FullImageViewController.h"
#define BACKGROUND_CELL_HEIGHT 300.0f
#define ORIGIN_Y_CELL_MESSAGE_LABEL 86.0f
#define TB_HEADER_HEIGHT 20.0f
#define AVATAR_SIZE CGSizeMake(70.0f, 70.0f)
#define isFromStatusViewController [self.parentViewController isKindOfClass:[UINavigationController class]]
#define IS_SELF_PROFILE [self.userNameOfUserProfileToDisplay isEqualToString:[PFUser currentUser].username]
@interface ProfileViewController ()<UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate,ELCImagePickerControllerDelegate,UICollectionViewDataSource,UICollectionViewDelegate,UIScrollViewDelegate>{
    UIImagePickerController *imagePicker;
    UIScrollView *fullPictureScrollView;
    FullImageViewController *fullSizeImageVC;
}
@property (nonatomic, strong) NSMutableArray *avatars;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewTopSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *usernameLabelTopSpaceConstraint;
@property (nonatomic, strong) NSIndexPath *selectedCollectionCellIndex;
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

    if(IS_SELF_PROFILE){
        self.followButton.hidden = YES;
        
        if(!isFromStatusViewController){
            self.fakeNavigationBar.hidden = YES;
        }else{
            self.fakeNavigationBar.hidden = NO;
            self.usernameLabelTopSpaceConstraint.constant = 64;
            [self.view layoutIfNeeded];
        }
        
    }else{
        
        self.userNameLabelTopSpaceToTopLayoutConstraint.constant = 64;
        self.tableViewTopSpaceConstraint.constant = 10;
        [self.view layoutIfNeeded];
        
        self.followButton.hidden = NO;
        self.fakeNavigationBar.hidden = NO;
        //other users cannot see my followers and following
        self.followerLabel.hidden = YES;
        self.followersTitleLabel.hidden= YES;
        self.followingLabel.hidden = YES;
        self.followingTitleLabel.hidden = YES;
    }
    
    //only set and pull avatar once per app usage
    [self setupAvatarsForUser:self.userNameOfUserProfileToDisplay];
}

-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    
//need to do something here. dont grab everything when user comes back to this tab
    [self fetchNewStatusWithCount:25 remainingTime:nil];
//this method needs rework
    [self updateUserInfoValues];
}

-(void)setupAvatarsForUser:(NSString *)username{
    
    //set avatar
    if(!self.avatars){
        self.avatars = [NSMutableArray array];
    }
    
    [Helper getAvatarForUser:username avatarType:AvatarTypeLeft isHighRes:NO completion:^(NSError *error, UIImage *image) {
        [self.avatars addObject:image];
        [self.collectionView reloadData];
        
        [Helper getAvatarForUser:username avatarType:AvatarTypeMid isHighRes:NO completion:^(NSError *error, UIImage *image) {
            [self.avatars addObject:image];
            [self.collectionView reloadData];
            
            [Helper getAvatarForUser:username avatarType:AvatarTypeRight isHighRes:NO completion:^(NSError *error, UIImage *image) {
                [self.avatars addObject:image];
                [self.collectionView reloadData];
            }];
        }];
    }];
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
    
    //fetch everything from local for fast loading
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    //pull from defaults for faster loading # dwindles, followers and following
    if (IS_SELF_PROFILE) {
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
        
    }else{
        __block NSMutableDictionary *map = [[defaults objectForKey:@"relationMap"] mutableCopy];
        //this is not first time user installs the app,update the "Follow" button copy accordingly
        if (map) {
            NSNumber *value = map[self.userNameOfUserProfileToDisplay];
            if (value.intValue == 1) {
                [self.followButton setTitle:@"Following" forState:UIControlStateNormal];
                self.followButton.userInteractionEnabled = YES;
            }else{
                [self.followButton setTitle:@"Follow Request Sent" forState:UIControlStateNormal];
                self.followButton.userInteractionEnabled = NO;
            }
        }
        
        PFQuery *query = [[PFQuery alloc] initWithClassName:@"FriendRequest"];
        [query whereKey:@"senderUsername" equalTo:[PFUser currentUser].username];
        [query whereKey:@"receiverUsername" equalTo:self.userNameOfUserProfileToDisplay];
        [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if (!error && object) {
                NSNumber *status = object[@"requestStatus"];
                if (status.intValue == 1) {
                    [self.followButton setTitle:@"Following" forState:UIControlStateNormal];
                    self.followButton.userInteractionEnabled = YES;
                }else{
                    [self.followButton setTitle:@"Follow Request Sent" forState:UIControlStateNormal];
                    self.followButton.userInteractionEnabled = NO;
                }
                if (!map) {
                    map = [NSMutableDictionary dictionary];
                }
                [map setObject:[NSNumber numberWithInt:status.intValue] forKey:self.userNameOfUserProfileToDisplay];
                [defaults setObject:map forKey:@"relationMap"];
                [defaults synchronize];
                
            }
        }];
    }
    
    
    //update this value
    PFQuery *query = [[PFQuery alloc] initWithClassName:@"Status"];
    [query whereKey:@"posterUsername" equalTo:self.userNameOfUserProfileToDisplay];
    [query countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        self.dwindleLabel.text = [NSString stringWithFormat:@"%d", number];
        
        if (IS_SELF_PROFILE) {
            [defaults setObject:[NSNumber numberWithInt:number] forKey:@"numberofposts"];
            [defaults setBool:YES forKey:@"hasDoneInitialStatusCount"];
            [defaults synchronize];
        }
    }];

    //only my profile needs to show # of followers and following
    if (IS_SELF_PROFILE) {
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
    }else{
        self.selectedCollectionCellIndex = nil;
    }
}

#pragma mark - image picker delegates

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *originalImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    //save to parse and local
    UIImage *scaledImage = [Helper scaleImage:originalImage downToSize:AVATAR_SIZE];
    NSData *data = UIImagePNGRepresentation(scaledImage);
    
    //save profile image to local and server
    [Helper saveAvatar:data avatarType:AvatarTypeMid forUser:[PFUser currentUser].username isHighRes:NO];
    [Helper saveAvatar:UIImagePNGRepresentation(originalImage) avatarType:AvatarTypeMid forUser:[PFUser currentUser].username isHighRes:YES];
    [self.avatars addObject:scaledImage];
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark ELCImagePickerControllerDelegate Methods

- (void)elcImagePickerController:(ELCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info
{
    
    //if user has only selected one image, then replace that single image. otherwise reload collectionview
    if (info.count == 1 && self.avatars.count>=1) {
        NSDictionary *dictionary = info[0];
        UIImage *image = dictionary[@"UIImagePickerControllerOriginalImage"];
        UIImage *scaledImage = [Helper scaleImage:image downToSize:AVATAR_SIZE];
        NSData *data = UIImagePNGRepresentation(scaledImage);
        
        [self.avatars replaceObjectAtIndex:self.selectedCollectionCellIndex.row withObject:image];
        [Helper saveAvatar:data avatarType:self.selectedCollectionCellIndex.row forUser:[PFUser currentUser].username isHighRes:NO];

    }else{
        
        for (NSUInteger i = info.count; i<self.avatars.count; i++) {
            [Helper removeAvatarWithAvatarType:i];
        }
        
        [self.avatars removeAllObjects];
        
        for (int i=0;i<info.count;i++) {
            NSDictionary *dict = info[i];
            UIImage *image = dict[@"UIImagePickerControllerOriginalImage"];
            UIImage *scaledImage = [Helper scaleImage:image downToSize:AVATAR_SIZE];
            NSData *data = UIImagePNGRepresentation(scaledImage);
            [Helper saveAvatar:data avatarType:i forUser:[PFUser currentUser].username isHighRes:NO];
            [Helper saveAvatar:UIImagePNGRepresentation(image) avatarType:i forUser:[PFUser currentUser].username isHighRes:YES];
            [self.avatars insertObject:scaledImage atIndex:i];
            
        }
    }
    
    [self.collectionView reloadData];
    
    
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
        view.textLabel.text = @"Live posts";
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

- (IBAction)followButtonTapped:(UIButton *)sender {
    
    if([sender.titleLabel.text isEqualToString:@"Follow"]){
        [Helper sendFriendRequestTo:self.userNameOfUserProfileToDisplay from:[PFUser currentUser].username];
        [self.followButton setTitle:@"Follow Request Sent" forState:UIControlStateNormal];
        self.followButton.userInteractionEnabled = NO;
    }else if([sender.titleLabel.text isEqualToString:@"Following Request Sent"]){
        self.followButton.userInteractionEnabled = NO;
    }else{
        //"Following"
        [self.followButton setTitle:@"Follow" forState:UIControlStateNormal];
        self.followButton.userInteractionEnabled = YES;
#warning put code here to unfollow this friend
        NSMutableArray *array = [[[PFUser currentUser] objectForKey:UsersAllowMeToFollow] mutableCopy];
        [array removeObject:self.userNameOfUserProfileToDisplay];
        [[PFUser currentUser] setObject:array forKey:UsersAllowMeToFollow];
        [[PFUser currentUser] saveInBackground];
#warning cloud code to remove self from friend's usersIAllowToFollowMe array
        
    }
}

#pragma mark - uicollectionview delegate 

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    if (!IS_SELF_PROFILE) {
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Camera",@"Gallery", nil];
        [sheet showFromTabBar:self.tabBarController.tabBar];
        self.selectedCollectionCellIndex = indexPath;
    }else{
        
        if (!fullSizeImageVC) {
            fullSizeImageVC = (FullImageViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"fullSizeVC"];
            fullSizeImageVC.username = self.userNameOfUserProfileToDisplay;
        }
        fullSizeImageVC.view.alpha = 0.0f;
        [self.view addSubview:fullSizeImageVC.view];
        [UIView animateWithDuration:.3 animations:^{
            fullSizeImageVC.view.alpha = 1.0f;
        }];
//        fullPictureScrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
//        fullPictureScrollView.pagingEnabled = YES;
//        fullPictureScrollView.backgroundColor = [UIColor blackColor];
//        fullPictureScrollView.alpha = 0.0f;
//        int i = 0;
//        for (UIImage *image in self.avatars) {
//            UIScrollView *scrollview = [[UIScrollView alloc] initWithFrame:CGRectMake(i*fullPictureScrollView.frame.size.width,
//                                                                                     0,
//                                                                                     fullPictureScrollView.frame.size.width,
//                                                                                      fullPictureScrollView.frame.size.height)];
//            scrollview.delegate = self;
//            scrollview.backgroundColor = [UIColor blackColor];
//            scrollview.opaque = YES;
//            scrollview.maximumZoomScale = 3.0f;
//            scrollview.minimumZoomScale = 1.0f;
//            UIImageView *imageview = [[UIImageView alloc] initWithFrame:CGRectMake(0,//i*fullPictureScrollView.frame.size.width,
//                                                                                   0,
//                                                                                   fullPictureScrollView.frame.size.width,
//                                                                                   fullPictureScrollView.frame.size.height)];
//            imageview.image = image;
//            imageview.tag = 99;
//            [scrollview addSubview:imageview];
//            [fullPictureScrollView addSubview:scrollview];
//            imageview.contentMode = UIViewContentModeScaleAspectFit;
//            i++;
//        }
//        fullPictureScrollView.contentSize = CGSizeMake(fullPictureScrollView.frame.size.width*self.avatars.count, fullPictureScrollView.frame.size.height);
//        [self.view addSubview:fullPictureScrollView];
//        [UIView animateWithDuration:.3 animations:^{
//            fullPictureScrollView.alpha = 1.0f;
//        }];
    }
}

#pragma mark - uiscrollviewdelegate

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    UIView *view = [scrollView viewWithTag:99];
    return view;
}

#pragma mark - uicollectionviewdatasource

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)collectionView.collectionViewLayout;
    if (self.avatars.count == 0|| self.avatars.count ==1) {
        layout.minimumLineSpacing = 0;
        layout.sectionInset = UIEdgeInsetsMake(0, 70, 0, 0);
    }else if (self.avatars.count == 2){
        layout.minimumLineSpacing = 23;
        layout.sectionInset = UIEdgeInsetsMake(0, 23, 0, 0);
    }else{
        layout.minimumLineSpacing = 0;
        layout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0);
    }

    if (self.avatars.count == 0) {
        return 1;
    }else{
        return self.avatars.count;
    }
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    ImageCollectionViewCell *cell = (ImageCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    if (self.avatars.count != 0) {
        cell.imageView.image = self.avatars[indexPath.row];
    }
    return cell;
}

@end
