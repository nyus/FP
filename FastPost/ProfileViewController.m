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
#import "Status.h"
#import "Helper.h"
//#import "StatusTableViewHeaderViewController.h"
#define BACKGROUND_CELL_HEIGHT 300.0f
#define ORIGIN_Y_CELL_MESSAGE_LABEL 86.0f

@interface ProfileViewController ()<StatusTableViewCellDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>{
    NSMutableArray *dataSource;
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
    [self fetchNewStatusWithCount:25 remainingTime:nil];
    
    if([self.presentingSource isEqualToString:@"statusViewController"]){
        self.editButton.hidden = YES;
    }else{
        self.followButton.hidden = YES;
    }

    //set avatar
    [Helper getAvatarForUser:[PFUser currentUser].username forImageView:self.avatarImageView];
    //# of dwindles
    PFQuery *query = [[PFQuery alloc] initWithClassName:@"Status"];
    [query whereKey:@"posterUsername" equalTo:[PFUser currentUser].username];
    [query countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        self.dwindleLabel.text = [NSString stringWithFormat:@"%d", number];
    }];
    
//    self.dwindleLabel.text =
    //set following. # of following is the count of friends minus one(since user is friend of himself)
    PFUser *me = [PFUser currentUser];
    self.followingLabel.text = [NSString stringWithFormat:@"%d",[me[@"friends"] count]-1];
    //set follower.
    self.followerLabel.text = [NSString stringWithFormat:@"%d",[me[@"followers"] count]];
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
    PFUser *user = [PFUser currentUser];
    user[@"avatar"] = [PFFile fileWithData:data];
    user[@"avatarUpdateDate"] = [NSDate date];
    [user saveInBackground];
    
    [picker dismissViewControllerAnimated:YES completion:^{
        self.avatarImageView.image = chosenImage;
    }];
}

-(void)fetchNewStatusWithCount:(int)count remainingTime:(NSNumber *)remainingTimeInSec{
    
    PFQuery *query = [PFQuery queryWithClassName:@"Status"];
    query.limit = count;
    [query orderByDescending:@"createdAt"];
    
//    [query whereKey:@"expirationDate" greaterThan:[NSDate date]];
//    if (remainingTimeInSec) {
//        [query whereKey:@"expirationDate" lessThan:[[NSDate date] dateByAddingTimeInterval:remainingTimeInSec.intValue]];
//    }
    [query whereKey:@"posterUsername" equalTo:[PFUser currentUser].username];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if (objects.count != 0) {

            if (dataSource.count > 0) {
                [dataSource removeAllObjects];
                
                for (int i = 0 ; i<objects.count; i++) {
                    Status *newStatus = [[Status alloc] initWithPFObject:objects[i]];
//                    newStatus.delegate = self;
                    if (!dataSource) {
                        dataSource = [NSMutableArray array];
                    }
                    [dataSource addObject:newStatus];
                }
                
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
            }else{
                for (PFObject *status in objects) {
                    Status *newStatus = [[Status alloc] initWithPFObject:status];
//                    newStatus.delegate = self;
                    if (!dataSource) {
                        dataSource = [NSMutableArray array];
                    }
                    [dataSource addObject:newStatus];
                }
                [self.tableView reloadData];
            }
        }else{
            //
            NSLog(@"0 items fetched from parse");
        }
        
    }];
}


#pragma mark - UITableViewDelete 

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
//    if(!dataSource){
//        //return background cell
//        return 1;
//    }else{
        // Return the number of rows in the section.
        return dataSource.count;
//    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
//    if(!dataSource || dataSource.count == 0){
//        //no status background cell
//        static NSString *CellIdentifier = @"BackgroundCell";
//        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
//        
//        return cell;
//    }else{
        static NSString *CellIdentifier = @"Cell";
        StatusTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        cell.delegate = self;
        // Configure the cell...
        cell.statusCellMessageLabel.text = [[dataSource objectAtIndex:indexPath.row] pfObject][@"message"];
        cell.statusCellUsernameLabel.text = [[[dataSource objectAtIndex:indexPath.row] pfObject] objectForKey:@"posterUsername"];
        BOOL revivable = [[dataSource[indexPath.row] pfObject][@"revivable"] boolValue];
        if (!revivable) {
            cell.statusCellReviveButton.hidden = YES;
        }
        //
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"HH:mm MM/dd/yy"];
        NSString *str = [formatter stringFromDate:[[dataSource objectAtIndex:indexPath.row] pfObject].updatedAt];
        cell.statusCellDateLabel.text = str;
        
        //if user avatar is saved, pull locally; otherwise pull from server and save it locally
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES);
        NSString *documentDirectory = paths[0];
        NSString *path = [documentDirectory stringByAppendingPathComponent:cell.statusCellUsernameLabel.text];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            
            //compare saved avater creation date with the current avatar date, if dont match then need to update
            NSError *accessAttriError;
            NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&accessAttriError];
            NSDate *fileCreatedDate = [attributes objectForKey:NSFileCreationDate];
            
            if (accessAttriError) {
                
            }else{
                PFQuery *query = [[PFQuery alloc] initWithClassName:[PFUser parseClassName]];
                [query whereKey:@"username" equalTo:cell.statusCellUsernameLabel.text];
                [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                    if (!error && object) {
                        PFUser *user = (PFUser *)object;
                        NSDate *serverAvatarCreationDate = user[@"avatarUpdateDate"];
                        if ([serverAvatarCreationDate isEqualToDate:fileCreatedDate]) {
                            //then just use local saved avatar
                            NSData *imageData = [[NSFileManager defaultManager] contentsAtPath:path];
                            cell.statusCellAvatarImageView.image = [UIImage imageWithData:imageData];
                        }else{
                            
                            PFFile *avatar = [user objectForKey:@"avatar"];
                            if (avatar != (PFFile *)[NSNull null] && avatar != nil) {
                                
                                [avatar getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                                    if (data && !error) {
                                        cell.statusCellAvatarImageView.image = [UIImage imageWithData:data];
                                        
                                        //save image to local
                                        NSError *removeError;
                                        [[NSFileManager defaultManager] removeItemAtPath:path error:&removeError];
                                        if (!removeError) {
                                            NSString *newPath = [documentDirectory stringByAppendingString:[NSString stringWithFormat:@"%@",user.username]];
                                            [[NSFileManager defaultManager]
                                             createFileAtPath:newPath
                                             contents:data
                                             attributes:@{NSFileCreationDate:user[@"avatarUpdateDate"]}];
                                        }
                                        
                                    }else{
                                        NSLog(@"error (%@) getting avatar of user %@",error.localizedDescription,user.username);
                                    }
                                }];
                            }
                        }
                        
                    }
                }];
            }
            
        }else{
            
            PFQuery *query = [[PFQuery alloc] initWithClassName:[PFUser parseClassName]];
            [query whereKey:@"username" equalTo:cell.statusCellUsernameLabel.text];
            [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                if (!error && object) {
                    PFUser *user = (PFUser *)object;
                    PFFile *avatar = [user objectForKey:@"avatar"];
                    if (avatar != (PFFile *)[NSNull null] && avatar != nil) {
                        
                        
                        [avatar getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                            if (data && !error) {
                                cell.statusCellAvatarImageView.image = [UIImage imageWithData:data];
                                
                                //save image to local
                                //save image to local
                                NSError *removeError;
                                [[NSFileManager defaultManager] removeItemAtPath:path error:&removeError];
                                if (!removeError) {
                                    NSString *newPath = [documentDirectory stringByAppendingString:[NSString stringWithFormat:@"%@",user.username]];
                                    [[NSFileManager defaultManager]
                                     createFileAtPath:newPath
                                     contents:data
                                     attributes:@{NSFileCreationDate:user[@"avatarUpdateDate"]}];
                                }
                            }else{
                                NSLog(@"error (%@) getting avatar of user %@",error.localizedDescription,user.username);
                            }
                        }];
                    }
                }
            }];
        }
        
        PFFile *picture = [[[dataSource objectAtIndex:indexPath.row] pfObject] objectForKey:@"picture"];
//        cell.statusCellCountDownLabel.text = [self minAndTimeFormatWithSecond:[[dataSource[indexPath.row] countDownMessage] intValue]];
        if (picture != (PFFile *)[NSNull null] && picture != nil) {
            
            //add spinner on image view to indicate pulling image
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            spinner.center = CGPointMake((int)cell.statusCellPhotoImageView.frame.size.width/2, (int)cell.statusCellPhotoImageView.frame.size.height/2);
            [cell.statusCellPhotoImageView addSubview:spinner];
            [spinner startAnimating];
            
            [picture getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                
                if (data && !error) {
                    cell.statusCellPhotoImageView.image = [UIImage imageWithData:data];
                }else{
                    NSLog(@"error (%@) getting status photo with status id %@",error.localizedDescription,[[[dataSource objectAtIndex:indexPath.row] pfObject] objectId]);
                }
                
                [spinner stopAnimating];
            }];
        }
        
        return cell;
//    }
    
}

//-(NSString *)minAndTimeFormatWithSecond:(int)seconds{
//    return [NSString stringWithFormat:@"%d:%02d",seconds/60,seconds%60];
//}
//
//-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
//    
//    //for non background cell
//    if(dataSource && dataSource.count != 0){
//        [[dataSource objectAtIndex:indexPath.row] startTimer];
//        
//        //update the count down text
//        StatusTableViewCell *scell = (StatusTableViewCell *)cell;
//        if ([scell.statusCellMessageLabel.text isEqualToString:[dataSource[indexPath.row] pfObject][@"message"]]) {
//            scell.statusCellCountDownLabel.text = [self minAndTimeFormatWithSecond:[[dataSource[indexPath.row] countDownMessage] intValue]];
//            if (![scell.statusCellCountDownLabel.text isEqualToString:@"0:00"]) {
//            }else{
//                [dataSource removeObjectAtIndex:indexPath.row];
//                [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:indexPath.row inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
//                
//                if(dataSource.count == 0){
//                    dataSource = nil;
//                    [self.tableView reloadData];
//                }
//            }
//        }
//    }
//}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if(!dataSource || dataSource.count == 0){
        return BACKGROUND_CELL_HEIGHT;
    }else{
        //determine height of label
        NSString *message = [[dataSource objectAtIndex:indexPath.row] pfObject][@"message"];
        
        CGSize maxSize = CGSizeMake(280, MAXFLOAT);
        
        CGRect rect = [message boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont fontWithName:@"AvenirNextCondensed-Regular" size:17]} context:nil];
        
        int numberOfLines = ceilf(rect.size.width/280.0f);
        CGFloat heightOfLabel = numberOfLines *rect.size.height;
        
        //determine if there is a picture
        
        PFFile *picture = [[[dataSource objectAtIndex:indexPath.row] pfObject] objectForKey:@"picture"];
        if (picture == (PFFile *)[NSNull null] || picture == nil) {
            //68 y origin of label
            return ORIGIN_Y_CELL_MESSAGE_LABEL + heightOfLabel + 10;
        }else{
            //68 y origin of label, 204 height of picture image view
            return ORIGIN_Y_CELL_MESSAGE_LABEL + heightOfLabel + 10 + 204 + 10;
        }
        
    }
}
//
//-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
//    headerViewVC = [[StatusTableViewHeaderViewController alloc] initWithNibName:@"StatusTableViewHeaderViewController" bundle:nil];
//    headerViewVC.delegate = self;
//    return headerViewVC.view;
//}
//
//-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
//    return 44.0f;
//}

@end
