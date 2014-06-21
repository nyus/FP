//
//  Helper.h
//  FastPost
//
//  Created by Sihang Huang on 1/12/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef enum{
    AvatarTypeLeft,
    AvatarTypeMid,
    AvatarTypeRight
} AvatarType;

@interface Helper : NSObject
@property (copy) void (^completion)(NSError *error, UIImage *image);
//Avatar
+(void)getAvatarForUser:(NSString *)username avatarType:(AvatarType)type completion:(void(^)(NSError *error, UIImage *image))completionBlock;
+(UIImage *)getLocalAvatarForUser:(NSString *)username avatarType:(AvatarType)type;
+(void)getServerAvatarForUser:(NSString *)username avatarType:(AvatarType)type completion:(void(^)(NSError *error, UIImage *image))completionBlock;
+(NSArray *)getAvatarsForSelf;

+(BOOL)isLocalAvatarExistForUser:(NSString *)username avatarType:(AvatarType)type;
+(void)saveAvatar:(NSData *)data avatarType:(AvatarType)type forUser:(NSString *)username;
+(void)saveAvatarToLocal:(NSData *)data avatarType:(AvatarType)type forUser:(NSString *)username;

+(void)removeAvatarWithAvatarType:(AvatarType)type;
//Send out friend request
+(void)sendFriendRequestTo:(NSString *)receiver from:(NSString *)sender;

//image processing
+(UIImage *)scaleImage:(UIImage *)image downToSize:(CGSize) size;
@end
