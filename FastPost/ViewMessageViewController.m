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
    
    //
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    
	// Do any additional setup after loading the view.
    self.messageTextView.text = self.messageObject.message;
    
    //bring up keyboard
    [self.enterMsgTextView becomeFirstResponder];
    
    
    if (self.messageObject.read.boolValue != YES) {
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
}

-(void)keyboardWillShow:(NSNotification *)sender{
    CGRect keyboardRect = [sender.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    self.enterMsgContainerViewBottomSpaceToBottomLayoutConstraint.constant = keyboardRect.size.height - self.bottomLayoutGuide.length;
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
