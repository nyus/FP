//
//  StatusTableViewHeaderViewController.h
//  FastPost
//
//  Created by Huang, Jason on 12/4/13.
//  Copyright (c) 2013 Huang, Jason. All rights reserved.
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
