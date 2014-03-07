//
//  NotificatonViewController.m
//  FastPost
//
//  Created by Huang, Jason on 3/7/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "NotificatonViewController.h"

@interface NotificatonViewController ()<UITableViewDataSource,UITableViewDelegate>

@end

@implementation NotificatonViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
