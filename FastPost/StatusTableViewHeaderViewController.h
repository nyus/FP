//
//  StatusTableViewHeaderViewController.h
//  FastPost
//
//  Created by Huang, Sihang on 12/4/13.
//  Copyright (c) 2013 Huang, Sihang. All rights reserved.
//

#import <UIKit/UIKit.h>

@class StatusTableViewHeaderViewController;
@protocol StatusTableViewHeaderViewDelegate <NSObject>

-(void)tbHeaderComposeNewStatusButtonTapped;
-(void)tbHeaderSettingButtonTapped;
-(void)tbHeaderAddFriendButtonTapped;
@end

@interface StatusTableViewHeaderViewController : UIViewController
@property(assign, nonatomic) id<StatusTableViewHeaderViewDelegate>delegate;

@end
