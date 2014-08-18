//
//  ViewAndSendMessageViewController.m
//  FastPost
//
//  Created by Huang, Jason on 8/18/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "ViewAndSendMessageViewController.h"

@implementation ViewAndSendMessageViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    
    //this is for setting constraint in the parent vc. need to be set become becomeFirstResponder
    self.isFromPushSegue = YES;
    [self.enterMessageTextView becomeFirstResponder];
}

@end
