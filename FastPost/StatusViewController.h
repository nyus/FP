//
//  StatusViewController.h
//  FastPost
//
//  Created by Sihang Huang on 1/6/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewControllerWithStatusTableView.h"
@interface StatusViewController : BaseViewControllerWithStatusTableView
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
