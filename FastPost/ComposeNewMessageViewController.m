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
#import "ExpirationTimePickerViewController.h"
@interface ComposeNewMessageViewController ()<UITableViewDataSource,UITableViewDelegate,UITextViewDelegate,ExpirationTimePickerViewControllerDelegate>{
    NSMutableArray *dataSource;
    ExpirationTimePickerViewController *expirationTimePickerVC;
    int expirationTimeInSec;
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
    
    dataSource = [NSMutableArray array];
    //skip current user's username
    for (NSString *username in [[PFUser currentUser] objectForKey:@"friends"]) {
        if([username isEqualToString:[PFUser currentUser].username]){
            continue;
        }
        [dataSource addObject:username];
    }
    
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
    return 1;
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

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([self.recipientsTextView.text isEqualToString:@""]) {
        self.recipientsTextView.text = cell.textLabel.text;
        self.recipientsTextView.font = [UIFont systemFontOfSize:19];
        self.recipientsTextView.textColor = [UIColor colorWithRed:0.0f green:122.0/255.0 blue:255.0/255.0 alpha:1];
    }else if ([self.recipientsTextView.text rangeOfString:cell.textLabel.text].location == NSNotFound) {
        //dont allow the same recipient from appearing more than one time
        self.recipientsTextView.text = [self.recipientsTextView.text stringByAppendingFormat:@", %@",cell.textLabel.text];
        self.recipientsTextView.font = [UIFont systemFontOfSize:19];
        self.recipientsTextView.textColor = [UIColor colorWithRed:0.0f green:122.0/255.0 blue:255.0/255.0 alpha:1];
        
    }
    
    //reason for the delay is, ios is calculating the new content size after the text gets changed. if there is no delay, wont get the accurate content size
    [self performSelector:@selector(adjustRecipientFieldHeight) withObject:nil afterDelay:0.01];
    //cancel highlight
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)adjustRecipientFieldHeight{
    //adjust height as number of recipients grow.
    if (self.recipientsTextView.contentSize.height > self.recipientContainerView.frame.size.height) {
        self.recipientContainerViewHeightConstraint.constant = self.recipientsTextView.contentSize.height;
    }
}

#pragma mark - UITextView

-(void)textViewDidBeginEditing:(UITextView *)textView{

}

- (IBAction)cancelButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)sendButtonTapped:(id)sender {
    
    //do nothing is there is no recipient or no message
    if ([self.recipientsTextView.text isEqualToString:@""] || [self.enterMessageTextView.text isEqualToString:@""]) {
        return;
    }
    
    NSString *recipientString = [self.recipientsTextView.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSArray *recipients = [recipientString componentsSeparatedByString:@","];
    for (NSString *recipient in recipients) {
        PFObject *message = [PFObject objectWithClassName:@"Message"];
        message[@"senderUsername"] = [PFUser currentUser].username;
        message[@"receiverUsername"]= recipient;
        message[@"message"] = self.enterMessageTextView.text;
        
        if (expirationTimeInSec == 0) {
            //default to 10 mins
            expirationTimeInSec = 10*60;
        }
        
        message[@"expirationTimeInSec"] = [NSNumber numberWithInt:expirationTimeInSec];
        message[@"expirationDate"] = [NSDate dateWithTimeIntervalSinceNow:expirationTimeInSec];
        message[@"read"] = [NSNumber numberWithBool:NO];
        //reset
        expirationTimeInSec = 0;
        
        [message saveInBackground];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}
- (IBAction)setTimeButtonTapped:(id)sender {
    //show picker
    //filter button typed
    if (!expirationTimePickerVC) {
        expirationTimePickerVC = [[ExpirationTimePickerViewController alloc] initWithNibName:@"ExpirationTimePickerViewController" bundle:nil type:PickerTypeRevive];
        expirationTimePickerVC.delegate = self;
        expirationTimePickerVC.view.frame = CGRectMake(0,
                                                       (self.view.frame.size.height - expirationTimePickerVC.view.frame.size.height)/2,
                                                       expirationTimePickerVC.view.frame.size.width,
                                                       expirationTimePickerVC.view.frame.size.height);
        expirationTimePickerVC.titleLabel.text = @"";
        
        UIToolbar *blurEffectToolBar = [[UIToolbar alloc] initWithFrame:expirationTimePickerVC.view.frame];
        blurEffectToolBar.barStyle = UIBarStyleDefault;
        //set a reference so that can remove it
        expirationTimePickerVC.blurToolBar = blurEffectToolBar;
        
        expirationTimePickerVC.view.alpha = 0.0f;
        expirationTimePickerVC.blurToolBar.alpha = 0.0f;
        [self.view.window addSubview:expirationTimePickerVC.view];
        [self.view.window insertSubview:blurEffectToolBar belowSubview:expirationTimePickerVC.view];
    }
    
    [UIView animateWithDuration:.3 animations:^{
        expirationTimePickerVC.view.alpha = 1.0f;
        expirationTimePickerVC.blurToolBar.alpha = 1.0f;
    }];
}

#pragma mark - ExpirationTimePickerViewControllerDelegate
-(void)revivePickerViewExpirationTimeSetToMins:(NSInteger)min andSecs:(NSInteger)sec andPickerView:(UIPickerView *)pickerView{
    //add time to status remotely
    expirationTimeInSec = min * 60 + sec;
}
@end
