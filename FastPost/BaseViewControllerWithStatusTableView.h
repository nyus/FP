//
//  BaseViewControllerWithStatusTableView.h
//  FastPost
//
//  Created by Sihang Huang on 1/14/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StatusTableViewCell.h"
@interface BaseViewControllerWithStatusTableView : UIViewController<UITableViewDataSource, UITableViewDelegate,StatusTableViewCellDelegate>
@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, assign) BOOL needSocialButtons;
@end
