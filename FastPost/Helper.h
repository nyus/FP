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
    AvartarTypeRight
} AvatarType;

@interface Helper : NSObject
+(void)getAvatarForUser:(NSString *)username avatarType:(AvatarType)type forImageView:(UIImageView *)imageView;
+(BOOL)getLocalAvatarForUser:(NSString *)username avatarType:(AvatarType)type forImageView:(UIImageView *)imageView;
+(void)getServerAvatarForUser:(NSString *)username avatarType:(AvatarType)type forImageView:(UIImageView *)imageView;
+(void)saveAvatar:(NSData *)data avatarType:(AvatarType)type forUser:(NSString *)username;
+(void)saveAvatarToLocal:(NSData *)data avatarType:(AvatarType)type forUser:(NSString *)username;
+(NSArray *)getAvatarsForSelf;
@end
