//
//  CommentStatusViewController.h
//  FastPost
//
//  Created by Sihang Huang on 3/12/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CommentStatusViewController : UIViewController
@property (nonatomic, strong) NSString *statusObjectId;
-(void)clearCommentTableView;
@end
