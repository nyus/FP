//
//  ComposeNewMessageViewController.m
//  FastPost
//
//  Created by Sihang Huang on 2/9/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "ComposeNewMessageViewController.h"
#import <Parse/Parse.h>
#import "Helper.h"
@interface ComposeNewMessageViewController ()<UITableViewDataSource,UITableViewDelegate,UITextViewDelegate>{
    NSArray *dataSource;
}

@end

@implementation ComposeNewMessageViewController

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
    //register for keyboard notification
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    
    dataSource = [[PFUser currentUser] objectForKey:@"friends"];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)keyboardWillShow:(NSNotification *)sender{
    CGRect keyboardRect = [sender.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];

    [UIView animateWithDuration:[sender.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue] delay:0 options:[sender.userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue] animations:^{
        self.enterMessageContainerView.frame = CGRectMake(self.enterMessageContainerView.frame.origin.x,
                                                          self.enterMessageContainerView.frame.origin.y - keyboardRect.size.height,
                                                          self.enterMessageContainerView.frame.size.width,
                                                          self.enterMessageContainerView.frame.size.height);

    } completion:^(BOOL finished) {
        self.enterMessageContainerViewBottomSpaceToBottomLayoutContraint.constant = keyboardRect.size.height;
    }];
}

#pragma mark - UITableView
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 0;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return dataSource.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];

    //username
    cell.textLabel.text = dataSource[indexPath.row];
    //profile picture
    [Helper getAvatarForUser:dataSource[indexPath.row] forImageView:cell.imageView];
    
    return cell;
}

#pragma mark - UITextView

-(void)textViewDidBeginEditing:(UITextView *)textView{

}

- (IBAction)cancelButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)sendButtonTapped:(id)sender {
}
@end
