//
//  Helper.m
//  FastPost
//
//  Created by Sihang Huang on 1/12/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "Helper.h"
#import <Parse/Parse.h>
#import "FPLogger.h"
static Helper *_helper;
static NSDictionary *_map;
@implementation Helper

+(void)saveAvatarToLocal:(NSData *)data avatarType:(AvatarType)type forUser:(NSString *)username{

    dispatch_queue_t queue = dispatch_queue_create("save avatar", NULL);
    dispatch_async(queue, ^{
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentDirectory = paths[0];
        NSString *path = [documentDirectory stringByAppendingFormat:@"/%@%@",username,[NSString stringWithFormat:@"%d",type]];
        
        NSError *writeError = nil;
        [data writeToFile:path options:NSDataWritingAtomic error:&writeError];
        if (writeError) {
            [FPLogger record:[NSString stringWithFormat:@"-saveAvatar write self avatar to file error %@",writeError.localizedDescription]];
            NSLog(@"-saveAvatar write self avatar to file error %@",writeError.localizedDescription);
        }
    });
    
}

+(void)saveAvatar:(NSData *)data avatarType:(AvatarType)type forUser:(NSString *)username{
    
    [Helper saveAvatarToLocal:data avatarType:type forUser:username];
    PFUser *user = [PFUser currentUser];
    user[@"avatar"] = [PFFile fileWithData:data];
    user[@"avatarUpdateDate"] = [NSDate date];
    user[@"avatarUpdated"] = [NSNumber numberWithBool:YES];
    [user saveInBackground];
    
}


+(BOOL)getLocalAvatarForUser:(NSString *)username avatarType:(AvatarType)type forImageView:(UIImageView *)imageView{
    //if user avatar is saved, pull locally; otherwise pull from server and save it locally
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = paths[0];
    NSString *path = [documentDirectory stringByAppendingFormat:@"/%@%@",username,[NSString stringWithFormat:@"%d",type]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        
        //use local saved avatar right away, then see if the avatar has been updated on the server
        NSData *imageData = [[NSFileManager defaultManager] contentsAtPath:path];
        imageView.image = [UIImage imageWithData:imageData];
        
        return YES;
    }
    
    return NO;
}


+(void)getServerAvatarForUser:(NSString *)username avatarType:(AvatarType)type forImageView:(UIImageView *)imageView{
    
    if (_map == nil) {
        _map = [NSDictionary dictionary];
    }
    //if the user doesnt have a profile picture, stop calling API for it for this particular usage. when the app starts next, it will try to hit the API again.
    NSNumber *value = [_map objectForKey:username];
    if (value && value.boolValue == NO) {
        return;
    }
    
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
                        [Helper saveAvatarToLocal:data avatarType:type forUser:username];
                        
                    }else{
                        [FPLogger record:[NSString stringWithFormat:@"error (%@) getting avatar of user %@",error.localizedDescription,user.username]];
                        NSLog(@"error (%@) getting avatar of user %@",error.localizedDescription,user.username);
                    }
                }];
            }else{
                [_map setValue:@NO forKey:username];
                
                [FPLogger record:[NSString stringWithFormat:@"no avater for user %@", user.username]];
                NSLog(@"no avater for user %@", user.username);
            }
        }
    }];
}

//this method first checks if there is a locally saved avatar image
//if there is no locally saved avatar image, pull from server and save the image to local.
+(void)getAvatarForUser:(NSString *)username avatarType:(AvatarType)type forImageView:(UIImageView *)imageView{

    //first fetch local, if not found, fetch from server
    if(![Helper getLocalAvatarForUser:username avatarType:type forImageView:imageView]){
        //set default header. becuase cells are being reused. imageView may have other user's avatar
        UIImage *image = [UIImage imageNamed:@"default-user-icon-profile"];
        imageView.image = image;
        [Helper getServerAvatarForUser:username avatarType:type forImageView:imageView];
    }
}

+(NSArray *)getAvatarsForSelf{
    NSMutableArray *images = [NSMutableArray array];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = paths[0];
    for (int i =0; i<3; i++) {
        
        NSString *path = [documentDirectory stringByAppendingFormat:@"/%@%@",[PFUser currentUser].username,[NSString stringWithFormat:@"%d",i]];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            
            //use local saved avatar right away, then see if the avatar has been updated on the server
            NSData *imageData = [[NSFileManager defaultManager] contentsAtPath:path];
            UIImage *image = [UIImage imageWithData:imageData];
            [images addObject:image];
        }
    }
    return images;
}

#pragma mark - friend request

+(void)sendFriendRequestTo:(NSString *)receiver from:(NSString *)sender{
    //when user followers another person, the user would be able to start seeing person's posts, but not untile person accepts user's friend quest can user start messaging this person
    [[PFUser currentUser] addUniqueObject:receiver forKey:UsersAllowMeToFollow];
    [[PFUser currentUser] saveInBackground];
    //so that this new user would be accessible
    [[PFUser currentUser] refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        
    }];
    
    //create a new FriendRequest object and send it to parse
    PFObject *request = [[PFObject alloc] initWithClassName:@"FriendRequest"];
    request[@"senderUsername"] = sender;
    request[@"receiverUsername"] = receiver;
    //FriendRequest.requestStatus
    //1. accepted 2. denied 3. not now 4. new request
    request[@"requestStatus"] = [NSNumber numberWithInt:4];
    [request saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            
            //send out push notification to Friend Requrest receiver
            //first query the PFUser(recipient) with the specific username
            PFQuery *innerQuery = [PFQuery queryWithClassName:[PFUser parseClassName]];
            [innerQuery whereKey:@"username" equalTo:receiver];
            //then query this PFuser set on PFInstallation
            PFQuery *query = [PFInstallation query];
            [query whereKey:@"user" matchesQuery:innerQuery];
            
            PFPush *push = [[PFPush alloc] init];
            [push setQuery:query];
            [push setMessage:[NSString stringWithFormat:@"%@ has sent you a follow request",sender]];
            [push sendPushInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!succeeded) {
                    [FPLogger record:[NSString stringWithFormat:@"Failed to send push from %@ to %@",sender,receiver]];
                }
            }];
            [FPLogger record:[NSString stringWithFormat:@"friend request %@ sent",request]];
            NSLog(@"friend request %@ sent",request);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Request sent!" delegate:self cancelButtonTitle:@"Done" otherButtonTitles:nil, nil];
            [alert show];
        }else{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Something went wrong, please try again." delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
            [alert show];
        }
    }];
}

@end
