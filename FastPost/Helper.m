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
        }else{
            PFFile *avatar = [PFUser currentUser][@"avatar"];
            [avatar getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                
                //user has the app installed but deleted it, and then redownload, pull avatar from parse
                if (data && !error) {
                    imageView.image = [UIImage imageWithData:data];
                    
                    //save to local
                    NSError *writeError;
                    [data writeToFile:path options:NSDataWritingAtomic error:&writeError];
                    if (writeError) {
                        NSLog(@"save self avatar to local failed with error %@",writeError);
                    }
                    
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
        
        //compare saved avater creation date with the current avatar date, if dont match then need to update
        NSError *accessAttriError;
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&accessAttriError];
        NSDate *fileCreatedDate = [attributes objectForKey:NSFileCreationDate];
        
        if (accessAttriError) {
            NSLog(@"access avatar for user %@ failed with error %@",username, accessAttriError.localizedDescription);
            return;
        }
        
        PFQuery *query = [[PFQuery alloc] initWithClassName:[PFUser parseClassName]];
        [query whereKey:@"username" equalTo:username];
        [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if (!error && object) {
                PFUser *user = (PFUser *)object;
                NSDate *serverAvatarCreationDate = user[@"avatarUpdateDate"];
                
                if ([serverAvatarCreationDate isEqualToDate:fileCreatedDate]) {
                    //then just use local saved avatar
                    NSData *imageData = [[NSFileManager defaultManager] contentsAtPath:path];
                    imageView.image = [UIImage imageWithData:imageData];
                }else{
                    
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
                                
                            }else{
                                NSLog(@"error (%@) getting avatar of user %@",error.localizedDescription,user.username);
                            }
                        }];
                    }
                }
                
            }else{
                NSLog(@"fet avatar error %@",error.localizedDescription);
            }
        }];
        
    }else{
        
        PFQuery *query = [[PFQuery alloc] initWithClassName:[PFUser parseClassName]];
        [query whereKey:@"username" equalTo:username];
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
                            
                            BOOL success = [[NSFileManager defaultManager]
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
