//
//  Helper.m
//  FastPost
//
//  Created by Sihang Huang on 1/12/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

/**
Photo Object: name(String) status(PFObject) username(String) file(PFFile) isHighRes(BOOL) position(Number->0,1,2, for avatar only)
For Posts: 
 whereKey:status equals:status
 whereKey:isHighRes equals:isHighres
 
For Profile:
 whereKey:user equals:user
 whereKey:isHighRes equals:isHighres
 sortByKey:position(optional)
 **/


#import "Helper.h"
#import <Parse/Parse.h>
#import "FPLogger.h"
static Helper *_helper;
static NSMutableDictionary *_map;
@implementation Helper

//get avatar
+(BOOL)isLocalAvatarExistForUser:(NSString *)username avatarType:(AvatarType)type isHighRes:(BOOL)isHighRes{
    //if user avatar is saved, pull locally; otherwise pull from server and save it locally
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = paths[0];
    NSString *path = [documentDirectory stringByAppendingFormat:@"/%@%@%@",username,[NSString stringWithFormat:@"%u",type],isHighRes?@"1":@"0"];
    
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

+(UIImage *)getLocalAvatarForUser:(NSString *)username avatarType:(AvatarType)type isHighRes:(BOOL)isHighRes{
    
    //if user avatar is saved, pull locally; otherwise pull from server and save it locally
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = paths[0];
    NSString *path = [documentDirectory stringByAppendingFormat:@"/%@%@%@",username,[NSString stringWithFormat:@"%u",type],isHighRes?@"1":@"0"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        
        //use local saved avatar right away, then see if the avatar has been updated on the server
        NSData *imageData = [[NSFileManager defaultManager] contentsAtPath:path];
        UIImage *image = [UIImage imageWithData:imageData];
        return image;
    }
    
    return nil;
}

+(void)getServerAvatarForUser:(NSString *)username avatarType:(AvatarType)type isHighRes:(BOOL)isHighRes completion:(void (^)(NSError *, UIImage *))completionBlock{
    
    if (_map == nil) {
        _map = [NSMutableDictionary dictionary];
    }
    //if the user doesnt have a profile picture, stop calling API for it for this particular usage. when the app starts next, it will try to hit the API again.
    NSNumber *value = [_map objectForKey:username];
    if (value && value.boolValue == NO) {
        return;
    }
    
    PFQuery *query = [[PFQuery alloc] initWithClassName:@"Photo"];
    [query whereKey:@"username" equalTo:username];
    [query whereKey:@"isHighRes" equalTo:[NSNumber numberWithBool:isHighRes]];
    [query whereKey:@"position" equalTo:[NSNumber numberWithInt:type]];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!error && object) {
            
            PFFile *avatar = (PFFile *)object[@"image"];
            [avatar getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                if (data && !error) {
                    UIImage *image = [UIImage imageWithData:data];
                    completionBlock(error, image);
                    //save image to local
                    [Helper saveAvatarToLocal:data avatarType:type forUser:username isHighRes:isHighRes];
                    
                }else{
                    [FPLogger record:[NSString stringWithFormat:@"error (%@) getting avatar of user %@",error.localizedDescription,username]];
                    NSLog(@"error (%@) getting avatar of user %@",error.localizedDescription,username);
                }
            }];
            
        }else{
            [_map setValue:@NO forKey:username];
            
            [FPLogger record:[NSString stringWithFormat:@"no avater for user %@", username]];
            NSLog(@"no avater for user %@",username);
        }
    }];
}

+(void)getAvatarForUser:(NSString *)username avatarType:(AvatarType)type isHighRes:(BOOL)isHighRes completion:(void (^)(NSError *, UIImage *))completionBlock{
    
    //first fetch local, if not found, fetch from server
    UIImage *image = [Helper getLocalAvatarForUser:username avatarType:type isHighRes:isHighRes];
    if (image) {
        completionBlock(nil,image);
    }else{
        [Helper getServerAvatarForUser:username avatarType:type isHighRes:isHighRes completion:^(NSError *error, UIImage *image) {
            completionBlock(error, image);
        }];
    }
}

//save avatar
+(void)saveAvatarToLocal:(NSData *)data avatarType:(AvatarType)type forUser:(NSString *)username isHighRes:(BOOL)isHighRes{

    dispatch_queue_t queue = dispatch_queue_create("save avatar", NULL);
    dispatch_async(queue, ^{
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentDirectory = paths[0];
        NSString *path = [documentDirectory stringByAppendingFormat:@"/%@%@%@",username,[NSString stringWithFormat:@"%u",type],isHighRes?@"1":@"0"];
        
        NSError *writeError = nil;
        [data writeToFile:path options:NSDataWritingAtomic error:&writeError];
        if (writeError) {
            [FPLogger record:[NSString stringWithFormat:@"-saveAvatar write self avatar to file error %@",writeError.localizedDescription]];
            NSLog(@"-saveAvatar write self avatar to file error %@",writeError.localizedDescription);
        }
    });
    
}

+(void)saveAvatar:(NSData *)data avatarType:(AvatarType)type forUser:(NSString *)username isHighRes:(BOOL)isHighRes{
    
    [_map setValue:@YES forKey:username];
    
    [Helper saveAvatarToLocal:data avatarType:type forUser:username isHighRes:isHighRes];
    
    PFFile *file = [PFFile fileWithData:data];
    [file saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            
            PFObject *object = [PFObject objectWithClassName:@"Photo"];
            [object setObject:username forKey:@"username"];
            [object setObject:file forKey:@"image"];
            [object setObject:[NSNumber numberWithBool:isHighRes] forKey:@"isHighRes"];
            [object setObject:[NSNumber numberWithInt:type] forKey:@"position"];
            [object saveInBackground];
        }
    }];
}

//only the currentUser can delete avatar
+(void)removeAvatarWithAvatarType:(AvatarType)type{
    
    PFQuery *query = [[PFQuery alloc] initWithClassName:@"Photo"];
    [query whereKey:@"username" equalTo:[PFUser currentUser].username];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error && objects.count!=0) {
            for (PFObject *object in objects) {
                [object deleteInBackground];
            }
        }
    }];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = paths[0];
    NSString *path = [documentDirectory stringByAppendingFormat:@"/%@%@%@",[PFUser currentUser].username,[NSString stringWithFormat:@"%d",type],@"1"];
    NSError *error;
    //remove high res
    [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    //remove low res
    path = [documentDirectory stringByAppendingFormat:@"/%@%@%@",[PFUser currentUser].username,[NSString stringWithFormat:@"%d",type],@"0"];
    [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
}

#pragma mark - friend request

+(void)sendFriendRequestTo:(NSString *)receiver from:(NSString *)sender{
    //when user followers another person, the user would be able to start seeing person's posts, but not untile person accepts user's friend quest can user start messaging this person
    [[PFUser currentUser] addUniqueObject:receiver forKey:UsersAllowMeToFollow];
    [[PFUser currentUser] saveInBackground];
    //so that this new user would be accessible
    [[PFUser currentUser] refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {}];
    
    //create a new FriendRequest object and send it to parse
    PFObject *request = [[PFObject alloc] initWithClassName:@"FriendRequest"];
    request[@"senderUsername"] = sender;
    request[@"receiverUsername"] = receiver;
    //FriendRequest.requestStatus
    //1. accepted 2. denied 3. not now 4. new request
    request[@"requestStatus"] = [NSNumber numberWithInt:4];
    [request saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSMutableDictionary *map = [[defaults objectForKey:@"relationMap"] mutableCopy];
            
            if (!map) {
                map = [NSMutableDictionary dictionary];
                
            }
            [map setObject:@4 forKey:receiver];
            [defaults setObject:map forKey:@"relationMap"];
            [defaults synchronize];
            
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

#pragma mark - image processing

+(UIImage *)scaleImage:(UIImage *)image downToSize:(CGSize) size{
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
    CGRect imageRect;
    if(image.size.width<image.size.height){
        //handle portrait photos
        float newWidth = image.size.width * size.height/image.size.height;
        imageRect = CGRectMake((size.width-newWidth)/2, 0.0, newWidth, size.height);
    }else{
        imageRect = CGRectMake(0.0, 0.0, size.width, size.height);
    }
    [image drawInRect:imageRect];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return scaledImage;
}

#pragma mark - formatting

+(NSString *)minAndTimeFormatWithSecond:(int)seconds{
    return [NSString stringWithFormat:@"%d:%02d",seconds/60,seconds%60];
}

@end
