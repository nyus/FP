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


//this method first checks if there is a locally saved avatar image, if so, check if this avatar still matches the one on the server by comparing avatarUpdateDate. If no longer valid, pull from server and then save to local again.
//if there is no locally saved avatar image, pull from server and save the image to local.
+(void)getAvatarForUser:(NSString *)username forImageView:(UIImageView *)imageView{
    
    //if user avatar is saved, pull locally; otherwise pull from server and save it locally
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = paths[0];
    NSString *path = [documentDirectory stringByAppendingPathComponent:username];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        
        //compare saved avater creation date with the current avatar date, if dont match then need to update
        NSError *accessAttriError;
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&accessAttriError];
        NSDate *fileCreatedDate = [attributes objectForKey:NSFileCreationDate];
        
        if (accessAttriError) {
            
        }else{
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
}
@end
