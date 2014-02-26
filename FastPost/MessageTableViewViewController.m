//
//  MessageTableViewViewController.m
//  FastPost
//
//  Created by Sihang Huang on 2/9/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "MessageTableViewViewController.h"
#import "MessageTableViewCell.h"
#import "Helper.h"
#import "SharedDataManager.h"
#import "Message.h"
#import "Message+Utilities.h"
#import <Parse/Parse.h>
#import "ViewMessageViewController.h"
@interface MessageTableViewViewController ()<UITableViewDataSource,UITableViewDelegate>{
    NSMutableArray *dataSource;
    NSMutableArray *hasTimerArray;
    NSString *messageToPass;
}

@end

@implementation MessageTableViewViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //refresh control
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshControlTriggerred:) forControlEvents:UIControlEventValueChanged];
    //on start up, fetch old messages
    [self fetchLocalMessage];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.refreshControl beginRefreshing];
    [self fetchNewMessage];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    messageToPass = nil;
}

-(void)refreshControlTriggerred:(id)sender{
    [self fetchNewMessage];
}

-(void)fetchLocalMessage{
    if (!dataSource) {
        dataSource = [NSMutableArray array];
        hasTimerArray = [NSMutableArray array];
    }
    
    NSArray *fetchResult = [self fetchAllLocalMessages];
    for (Message *message in fetchResult) {
        [dataSource addObject:message];
        [hasTimerArray addObject:[NSNumber numberWithBool:NO]];
    }

}

-(void)fetchNewMessage{
    
    if (!dataSource) {
        dataSource = [NSMutableArray array];
        hasTimerArray = [NSMutableArray array];
    }
    
#warning need to cache result
    PFQuery *query = [[PFQuery alloc] initWithClassName:@"Message"];
    [query whereKey:@"receiverUsername" equalTo:[PFUser currentUser].username];
    [query orderByDescending:@"createdAt"];

    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error && objects && objects.count!=0) {
            
            int delta =  objects.count - dataSource.count;
            //these are the new messages
            for(int i = 1; i<=delta;i++){
                PFObject *object = objects[i-1];
                Message *message = [NSEntityDescription insertNewObjectForEntityForName:@"Message" inManagedObjectContext:[SharedDataManager sharedInstance].managedObjectContext];
                message.createdAt = object.createdAt;
                message.updatedAt = object.updatedAt;
                message.message = object[@"message"];
                message.senderUsername = object[@"senderUsername"];
                message.receiverUsername = object[@"receiverUsername"];
                message.read = object[@"read"];
                message.objectid = object.objectId;
                message.expirationDate = object[@"expirationDate"];
                message.expirationTimeInSec = object[@"expirationTimeInSec"];
                message.countDown = object[@"expirationTimeInSec"];
                
                //before we could have fetched some old messages first so we need the new ones to be the top
                [dataSource insertObject:message atIndex:0];
                [hasTimerArray insertObject:[NSNumber numberWithBool:NO] atIndex:0];
            }
            
            //update already existent messages
            for(int i = delta ; i<objects.count;i++){
                PFObject *object = objects[i];
                Message *message = dataSource[i];
                [message updateSelfFromPFObject:object];
            }
            
            //save before we pull old messages from database
            [[SharedDataManager sharedInstance] saveContext];
            //reload
            [self.tableView reloadData];
            [self.refreshControl endRefreshing];
        }
        
        
    }];
}

#pragma mark - core data fetch 

-(NSArray *)fetchAllLocalMessages{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Message"];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    NSError *fetchError;
    NSArray *fetchResult = [[SharedDataManager sharedInstance].managedObjectContext executeFetchRequest:request error:&fetchError];
    if (fetchError) {
        NSLog(@"fetch all local msg error is %@",fetchError.localizedDescription);
        return nil;
    }else{
        return fetchResult;
    }
}

-(NSArray *)fetchMessageFromLocalDatabaseWithCount:(int)count andOffSet:(int)offset{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Message"];
    [request setFetchLimit:count];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    
    NSError *fetchError;
    NSArray *fetchResult = [[SharedDataManager sharedInstance].managedObjectContext executeFetchRequest:request error:&fetchError];
    if (fetchError) {
        NSLog(@"fetch error is %@",fetchError.localizedDescription);
        return nil;
    }else{
        return fetchResult;
    }

}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.

    return dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *CellIdentifier = @"cell";
    MessageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    //sender profile picture
    Message *msg = (Message *)dataSource[indexPath.row];
    [Helper getAvatarForUser:msg.senderUsername forImageView:cell.msgCellProfileImageView];
    //sender name
    cell.msgCellUsernameLabel.text = msg.senderUsername;
    //count down label
    cell.msgCellCountDownLabel.text = [self minAndTimeFormatWithSecond:msg.countDown.intValue];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //do nothing if the msg has expired
    Message *msg = (Message *)dataSource[indexPath.row];
    if (msg.countDown.intValue == 0) {
        return;
    }else{
        messageToPass = msg.message;
        [self performSegueWithIdentifier:@"toViewMessage" sender:self];
    }
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (![hasTimerArray[indexPath.row] boolValue]) {
        [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(handleTimer:) userInfo:indexPath repeats:YES];
        [hasTimerArray replaceObjectAtIndex:indexPath.row withObject:[NSNumber numberWithBool:YES]];
    }
}

#pragma mark - Count Down Logic

-(void)handleTimer:(NSTimer *)timer{

    NSIndexPath *path = (NSIndexPath *)timer.userInfo;
    Message *msg = (Message *)dataSource[path.row];
    msg.countDown = [NSNumber numberWithInt:msg.countDown.intValue - 1];

    if (msg.countDown.intValue < 0) {
        msg.countDown = [NSNumber numberWithInt:0];
        [timer invalidate];
    }else{
        MessageTableViewCell *cell = (MessageTableViewCell *)[self.tableView cellForRowAtIndexPath:path];
        cell.msgCellCountDownLabel.text = [self minAndTimeFormatWithSecond:msg.countDown.intValue];
    }
    
    [[SharedDataManager sharedInstance] saveContext];
}

//-(void)statusObjectTimeUpWithObject:(Status *)object{
//    NSInteger index = [self.dataSource indexOfObject:object];
//    StatusTableViewCell *cell = (StatusTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
//    if ([cell.statusCellMessageLabel.text isEqualToString:[object.pfObject objectForKey:@"message"]]) {
//        //        [cell blurCell];
//        [self.dataSource removeObject:object];
//        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationRight];
//        //if there is no status anymore, need to reload to show the background cell
//        if(self.dataSource.count == 0){
//            //setting self.dataSource to nil prevents talbeview from crashing.
//            self.dataSource = nil;
//            [self.tableView reloadData];
//        }
//    }
//}

//-(void)statusObjectTimerCount:(int)count withStatusObject:(Status *)object{
//    NSInteger index = [self.dataSource indexOfObject:object];
//    StatusTableViewCell *cell = (StatusTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
//    if ([cell.statusCellMessageLabel.text isEqualToString:[object.pfObject objectForKey:@"message"]]) {
//        //convert seconds into min and second
//        cell.statusCellCountDownLabel.text = [self minAndTimeFormatWithSecond:object.countDownMessage.intValue];
//    }
//}

-(NSString *)minAndTimeFormatWithSecond:(int)seconds{
    return [NSString stringWithFormat:@"%d:%02d",seconds/60,seconds%60];
}

#pragma mark - Segue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"toViewMessage"]) {
        ViewMessageViewController *vc = (ViewMessageViewController *)segue.destinationViewController;
        vc.message = messageToPass;
    }
}
@end
