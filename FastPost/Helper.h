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
+(void)getAvatarForUser:(NSString *)username avatarType:(AvatarType)type isHighRes:(BOOL)isHighRes completion:(void(^)(NSError *error, UIImage *image))completionBlock;
+(UIImage *)getLocalAvatarForUser:(NSString *)username avatarType:(AvatarType)type isHighRes:(BOOL)isHighRes;
+(void)getServerAvatarForUser:(NSString *)username avatarType:(AvatarType)type isHighRes:(BOOL)isHighRes completion:(void(^)(NSError *error, UIImage *image))completionBlock;

+(BOOL)isLocalAvatarExistForUser:(NSString *)username avatarType:(AvatarType)type isHighRes:(BOOL)isHighRes;
+(void)saveAvatar:(NSData *)data avatarType:(AvatarType)type forUser:(NSString *)username isHighRes:(BOOL)isHighRes;
+(void)saveAvatarToLocal:(NSData *)data avatarType:(AvatarType)type forUser:(NSString *)username isHighRes:(BOOL)isHighRes;

+(void)removeAvatarWithAvatarType:(AvatarType)type;
//Send out friend request
+(void)sendFriendRequestTo:(NSString *)receiver from:(NSString *)sender;

//image processing
+(UIImage *)scaleImage:(UIImage *)image downToSize:(CGSize) size;

//formatting
+(NSString *)minAndTimeFormatWithSecond:(int)seconds;
@end
