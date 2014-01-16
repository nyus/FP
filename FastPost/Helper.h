//
//  Helper.h
//  FastPost
//
//  Created by Sihang Huang on 1/12/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Helper : NSObject
+(void)getAvatarForUser:(NSString *)username forImageView:(UIImageView *)imageView;
+(void)saveAvatar:(NSData *)data forUser:(NSString *)username;
+(void)getAvatarForSelfOnImageView:(UIImageView *)imageView;
@end
