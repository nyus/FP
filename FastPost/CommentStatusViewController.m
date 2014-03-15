//
//  CommentStatusViewController.m
//  FastPost
//
//  Created by Sihang Huang on 3/12/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "CommentStatusViewController.h"
#import <Parse/Parse.h>
@interface CommentStatusViewController ()

@end

@implementation CommentStatusViewController

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


-(void)sendComment{
    PFQuery *query = [[PFQuery alloc] initWithClassName:@"Comment"];
    [query whereKey:@"objectId" equalTo:self.statusObjectId];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!error) {
            //create comment object
            PFObject *comment = [[PFObject alloc] initWithClassName:@"Comment"];
            comment[@"senderUsername"] = [PFUser currentUser].username;
            comment[@"statusId"] = self.statusObjectId;
#warning put textview content here
            comment[@"contentString"] = nil;

            //increase comment count on Status object
            object[@"commentCount"] = [NSNumber numberWithInt:[object[@"commentCount"] intValue] +1];

            [comment saveInBackground];
            [object saveInBackground];
        }
    }];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
