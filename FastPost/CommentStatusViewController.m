//
//  CommentStatusViewController.m
//  FastPost
//
//  Created by Sihang Huang on 3/12/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "CommentStatusViewController.h"
#import <Parse/Parse.h>
#import "CommentTableViewCell.h"
#import "Helper.h"
#define COMMENT_LABEL_WIDTH 234.0f
@interface CommentStatusViewController ()<UITableViewDataSource,UITableViewDelegate>{
    //cache cell height
    NSMutableDictionary *cellHeightMap;
    UISwipeGestureRecognizer *swipeGesture;
}
@property (strong, nonatomic) NSArray *dataSource;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *enterMessageContainerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *enterMessageContainerViewBottomSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewHeightConstraint;

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
    if (!swipeGesture) {
        swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
        swipeGesture.direction = UISwipeGestureRecognizerDirectionRight;
    }
    [self.view addGestureRecognizer:swipeGesture];
}

-(void)handleSwipe:(UISwipeGestureRecognizer *)swipe{
    [UIView animateWithDuration:1 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0 options:UIViewAnimationOptionTransitionNone animations:^{
        
        self.view.frame = CGRectMake(320, 100, 50,50);
    } completion:nil];
}

-(void)setStatusObjectId:(NSString *)statusObjectId{
    //fetch all the comments
    PFQuery *query = [[PFQuery alloc] initWithClassName:@"Comment"];
    [query whereKey:@"statusId" equalTo:statusObjectId];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error && objects) {
            self.dataSource = objects;
            [self.tableView reloadData];
        }
    }];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)clearCommentTableView{
    self.dataSource = nil;
    [self.tableView reloadData];
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

#pragma mark - UITableViewDelete

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    return self.dataSource.count;
}

//hides the liine separtors when data source has 0 objects
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] init];
    
    return view;
}

-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 100;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    CommentTableViewCell *cell = (CommentTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    PFObject *comment = self.dataSource[indexPath.row];
    cell.commentStringLabel.text = comment[@"contentString"];
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(!self.dataSource || self.dataSource.count == 0){
        return 100.0f;
    }else{
        
        PFObject *comment = self.dataSource[indexPath.row];
        NSString *key =[NSString stringWithFormat:@"%lu",(unsigned long)comment.hash];
        //        NSLog(@"indexPath:%@",indexPath);
        //is cell height has been calculated, return it
        if ([cellHeightMap objectForKey:key]) {
            //            NSLog(@"return stored cell height: %f",[[cellHeightMap objectForKey:key] floatValue]);
            return [[cellHeightMap objectForKey:key] floatValue];
            
        }else{
            
            NSString *contentString = comment[@"contentString"];
            CGRect boundingRect =[contentString boundingRectWithSize:CGSizeMake(COMMENT_LABEL_WIDTH, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:13]} context:nil];  
            [cellHeightMap setObject:@(boundingRect.size.height+10) forKey:key];
            return boundingRect.size.height+10;
        }
    }
}

@end
