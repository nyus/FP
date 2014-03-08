//
//  TabBarViewController.m
//  FastPost
//
//  Created by Sihang Huang on 3/6/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "TabBarViewController.h"

@interface TabBarViewController ()

@end

@implementation TabBarViewController

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
    
    
    //set tab bar item tint color
    [[UITabBar appearance] setTintColor:[UIColor colorWithRed:26.0/255.0 green:207.0/255.0 blue:244.0/255.0 alpha:1]];
    
    
    int i = 0;
    for (UITabBarItem *tabBarItem in self.tabBar.items) {
        if (i==0) {
            UIImage *unselectedImage = [UIImage imageNamed:@"feed_tab"];
            UIImage *selectedImage = [UIImage imageNamed:@"feed_tab"];
            
            [tabBarItem setImage:unselectedImage];
            [tabBarItem setSelectedImage: [selectedImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
        }else if (i==1){
            UIImage *unselectedImage = [UIImage imageNamed:@"profile_tab"];
            UIImage *selectedImage = [UIImage imageNamed:@"profile_tab"];
            
            [tabBarItem setImage:unselectedImage];
            [tabBarItem setSelectedImage: [selectedImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
        }else if (i==2){
            UIImage *unselectedImage = [UIImage imageNamed:@"message_tab"];
            UIImage *selectedImage = [UIImage imageNamed:@"message_tab"];
            
            [tabBarItem setImage:unselectedImage];
            [tabBarItem setSelectedImage: [selectedImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
        }else{
            UIImage *unselectedImage = [UIImage imageNamed:@"profile_tab"];
            UIImage *selectedImage = [UIImage imageNamed:@"profile_tab"];
            
            [tabBarItem setImage:unselectedImage];
            [tabBarItem setSelectedImage: [selectedImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
        }
        i++;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
