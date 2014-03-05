//
//  Helper.m
//  FastPost
//
//  Created by Sihang Huang on 1/12/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "Helper.h"
#import <Parse/Parse.h>
static Helper *_helper;
@implementation Helper

+(void)getAvatarForSelfOnImageView:(UIImageView *)imageView{
    
    dispatch_queue_t queue = dispatch_queue_create("getAvatar", NULL);
    dispatch_async(queue, ^{
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentDirectory = paths[0];
        NSString *path = [documentDirectory stringByAppendingFormat:@"/%@",[PFUser currentUser].username];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            imageView.image = [UIImage imageWithData:[[NSFileManager defaultManager] contentsAtPath:path]];
            
            //see if there is a new avatar on the server
            PFQuery *query = [[PFQuery alloc] initWithClassName:[PFUser parseClassName]];
            [query whereKey:@"username" equalTo:[PFUser currentUser].username];
            [query whereKey:@"avatarUpdated" equalTo:[NSNumber numberWithBool:YES]];
            [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                
                if (!error && object) {
                    PFUser *user = (PFUser *)object;
                    
                    PFFile *avatar = [user objectForKey:@"avatar"];
                    if (avatar != (PFFile *)[NSNull null] && avatar != nil) {
                        
                        [avatar getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                            if (data && !error) {
                                imageView.image = [UIImage imageWithData:data];
                                
                                //save image to local
                                [[NSFileManager defaultManager]
                                 createFileAtPath:path
                                 contents:data
                                 attributes:@{NSFileCreationDate:user[@"avatarUpdateDate"]}];

                                
                                //set PFUser's avatarUpdated to NO so that next time if avatar gets updated we will know
                                user[@"avatarUpdated"] = [NSNumber numberWithBool:NO];
                                [user saveInBackground];
                                
                            }else{
                                NSLog(@"error (%@) getting avatar of user %@",error.localizedDescription,user.username);
                            }
                        }];
                    }
                    
                }else{
                    NSLog(@"fet avatar error %@",error.localizedDescription);
                }
            }];
            
        }else{
            PFFile *avatar = [PFUser currentUser][@"avatar"];
            [avatar getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                
                //user has the app installed but deleted it, and then redownload, pull avatar from parse
                if (data && !error) {
                    imageView.image = [UIImage imageWithData:data];

                    //save image to local
                    [[NSFileManager defaultManager]
                     createFileAtPath:path
                     contents:data
                     attributes:@{NSFileCreationDate:[PFUser currentUser][@"avatarUpdateDate"]}];

                }else{
                    UIImage *image = [UIImage imageNamed:@"default-user-icon-profile"];
                    imageView.image = image;
                }
                //first time usage. user the default place holder
                //else{}
            }];
        }
    });
}

+(void)saveAvatar:(NSData *)data forUser:(NSString *)username{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = paths[0];
    NSString *path = [documentDirectory stringByAppendingFormat:@"/%@",username];
    
    NSError *writeError = nil;
    [data writeToFile:path options:NSDataWritingAtomic error:&writeError];
    
    PFUser *user = [PFUser currentUser];
    user[@"avatar"] = [PFFile fileWithData:data];
    user[@"avatarUpdateDate"] = [NSDate date];
    user[@"avatarUpdated"] = [NSNumber numberWithBool:YES];
    [user saveInBackground];
    
    if (writeError) {
        NSLog(@"write to file error %@",writeError.localizedDescription);
    }
    
}

//this method first checks if there is a locally saved avatar image, if so, check if this avatar still matches the one on the server by comparing avatarUpdateDate. If no longer valid, pull from server and then save to local again.
//if there is no locally saved avatar image, pull from server and save the image to local.
+(void)getAvatarForUser:(NSString *)username forImageView:(UIImageView *)imageView{

    //if user avatar is saved, pull locally; otherwise pull from server and save it locally
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = paths[0];
    NSString *path = [documentDirectory stringByAppendingFormat:@"/%@",username];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {

        //use local saved avatar right away, then see if the avatar has been updated on the server
        NSData *imageData = [[NSFileManager defaultManager] contentsAtPath:path];
        imageView.image = [UIImage imageWithData:imageData];
        
        //see if there is a new avatar on the server
        PFQuery *query = [[PFQuery alloc] initWithClassName:[PFUser parseClassName]];
        [query whereKey:@"username" equalTo:username];
        [query whereKey:@"avatarUpdated" equalTo:[NSNumber numberWithBool:YES]];
        [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            
            if (!error && object) {
                PFUser *user = (PFUser *)object;
                
                PFFile *avatar = [user objectForKey:@"avatar"];
                if (avatar != (PFFile *)[NSNull null] && avatar != nil) {
                    
                    [avatar getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                        if (data && !error) {
                            imageView.image = [UIImage imageWithData:data];
                            
                            //save image to local
                            [[NSFileManager defaultManager]
                             createFileAtPath:path
                             contents:data
                             attributes:@{NSFileCreationDate:user[@"avatarUpdateDate"]}];
                            
                            //set PFUser's avatarUpdated to NO so that next time if avatar gets updated we will know
                            user[@"avatarUpdated"] = [NSNumber numberWithBool:NO];
                            [user saveInBackground];
                            
                        }else{
                            NSLog(@"error (%@) getting avatar of user %@",error.localizedDescription,user.username);
                        }
                    }];
                }

            }else{
                NSLog(@"fet avatar error %@",error.localizedDescription);
            }
        }];
        
    }else{
        
        //set default header. becuase cells are being reused. imageView may have other user's avatar
        UIImage *image = [UIImage imageNamed:@"default-user-icon-profile"];
        imageView.image = image;
        
        PFQuery *query = [[PFQuery alloc] initWithClassName:[PFUser parseClassName]];
        [query whereKey:@"username" equalTo:username];
        [query whereKey:@"avatar" notEqualTo:[NSNull null]];
        [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if (!error && object) {
                PFUser *user = (PFUser *)object;
                PFFile *avatar = [user objectForKey:@"avatar"];
                if (avatar != (PFFile *)[NSNull null] && avatar != nil) {
                    
                    [avatar getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                        if (data && !error) {
                            imageView.image = [UIImage imageWithData:data];
                            
                            //save image to local
                            //save image to local
                            NSError *removeError;
                            [[NSFileManager defaultManager] removeItemAtPath:path error:&removeError];
                            NSError *writeError;
                            [data writeToFile:path options:NSDataWritingAtomic error:&writeError];
                            
                            [[NSFileManager defaultManager]
                                 createFileAtPath:path
                                 contents:data
                                 attributes:@{NSFileCreationDate:user[@"avatarUpdateDate"]}];

                        }else{
                            NSLog(@"error (%@) getting avatar of user %@",error.localizedDescription,user.username);
                        }
                    }];
                }else{
                    NSLog(@"no avater for user %@", user.username);
                }
            }
        }];
    }
}
@end
