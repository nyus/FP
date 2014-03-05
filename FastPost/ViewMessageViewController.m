//
//  ViewMessageViewController.m
//  FastPost
//
//  Created by Huang, Jason on 2/26/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "ViewMessageViewController.h"
#import <Parse/Parse.h>
#import "SharedDataManager.h"
@interface ViewMessageViewController ()

@end

@implementation ViewMessageViewController

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
    self.messageTextView.text = self.messageObject.message;
    
    //update read property in core data
    self.messageObject.read = [NSNumber numberWithBool:YES];
    [[SharedDataManager sharedInstance] saveContext];
    
    //update read property on the server
    PFQuery *query = [[PFQuery alloc] initWithClassName:@"Message"];
    [query whereKey:@"objectId" equalTo:self.messageObject.objectid];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!error && object) {
            object[@"read"] = [NSNumber numberWithBool:YES];
            [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!succeeded) {
                    NSLog(@"set message %@ status to read",object);
                }
            }];
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
