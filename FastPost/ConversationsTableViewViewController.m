//
//  MessageTableViewViewController.m
//  FastPost
//
//  Created by Sihang Huang on 2/9/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

/*
 in viewWillAppear, first fetch local messages, then check server and see if there is a new conversation being created / new messages created for exsiting conversation. 
 - if new conversation, create Conversation object, save it to local
 - if new messages, find out which converation it belongs to, and light up the indicator to indicate new messages
 - new messages will be pulled when go into detail view
 */
#import "ConversationsTableViewViewController.h"
#import "MessageTableViewCell.h"
#import "SharedDataManager.h"
#import "Message.h"
#import "Message+Utilities.h"
#import <Parse/Parse.h>
#import "ViewMessageViewController.h"
#import "Conversation.h"
#import "GenericReviveInputViewController.h"
@interface ConversationsTableViewViewController ()<UITableViewDataSource,UITableViewDelegate>{
    NSMutableArray *dataSource;
    Message *messageToPass;
    BOOL comingSoon;
    NSMutableArray *localConversationArray;
    NSIndexPath *selectedIndexpath;
}

@end

@implementation ConversationsTableViewViewController

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
    
    comingSoon = NO;
    //compose button on the top right has been deleted. it modally presents compose new message view controller
    if (!comingSoon) {
        
        //refresh control
        self.refreshControl = [[UIRefreshControl alloc] init];
        [self.refreshControl addTarget:self action:@selector(refreshControlTriggerred:) forControlEvents:UIControlEventValueChanged];
        //on start up, fetch old messages
//        [self fetchLocalConversation];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (!comingSoon) {
        [self.refreshControl beginRefreshing];
        [self fetchLocalConversation];
        [self fetchServerConversation];
    }
    
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
}

-(void)refreshControlTriggerred:(id)sender{
    [self fetchServerConversation];
}

-(void)fetchLocalConversation{
    
    localConversationArray = nil;
//    if (!localConversationArray) {
    localConversationArray = [NSMutableArray array];
//    }

    NSArray *fetchResult = [self fetchAllLocalMessages];
    for (Conversation *conversation in fetchResult) {
        [localConversationArray addObject:conversation];
    }
    [self.tableView reloadData];
}

-(void)fetchServerConversation{
    
    NSMutableArray *objectIDs = [NSMutableArray array];
    for (Conversation *con in localConversationArray) {
        [objectIDs addObject:con.objectid];
    }
    
    PFQuery *query = [[PFQuery alloc] initWithClassName:@"Conversation"];
    [query whereKey:@"objectid" notContainedIn:objectIDs];
    [query whereKey:@"participants" containsAllObjectsInArray:@[[PFUser currentUser].username]];
    [query orderByAscending:@"lastUpdateDate"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error && objects &&objects.count!=0) {
            NSMutableArray *indexPathsArray = [NSMutableArray array];
            int i = 0;
            for (PFObject *pfConversation in objects) {
                Conversation *conversation = [NSEntityDescription insertNewObjectForEntityForName:@"Conversation" inManagedObjectContext:[SharedDataManager sharedInstance].managedObjectContext];
                conversation.participants = pfConversation[@"participants"];
                conversation.objectid = pfConversation[@"objectid"];
                conversation.lastUpdateDate = pfConversation[@"lastUpdateDate"];
                conversation.lastMessageContent = pfConversation[@"lastMessageContent"];
                [localConversationArray insertObject:conversation atIndex:0];
                [[SharedDataManager sharedInstance] saveContext];
                
                //
                NSIndexPath *path = [NSIndexPath indexPathForRow:i inSection:0];
                [indexPathsArray addObject:path];
                i++;
            }
            
            //reload
            [self.tableView insertRowsAtIndexPaths:indexPathsArray withRowAnimation:UITableViewRowAnimationAutomatic];

        }
        [self.refreshControl endRefreshing];
    }];
}

#pragma mark - core data fetch 

-(NSArray *)fetchAllLocalMessages{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Conversation"];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"lastUpdateDate" ascending:NO];
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
    if (comingSoon) {
        return 1;
    }else{
        return localConversationArray.count;
    }
}

//hides the liine separtors when data source has 0 objects
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] init];
    
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (comingSoon) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"comingSoon" forIndexPath:indexPath];
        return cell;
    }else{
        static NSString *CellIdentifier = @"cell";
        __block MessageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        // Configure the cell...
        //sender profile picture
        Conversation *conversation = (Conversation *)localConversationArray[indexPath.row];
        NSMutableString *string = [NSMutableString string];
        [string appendString:@"me"];
        for (NSString *username in conversation.participants) {
            if ([username isEqualToString:[PFUser currentUser].username]) {
                continue;
            }
            [string appendString:@","];
            [string appendString:@" "];
            [string appendString:username];

        }
        cell.participantsLabel.text = string;
        
        return cell;
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (comingSoon) {
        return;
    }
    
    selectedIndexpath = indexPath;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (comingSoon) {
        return;
    }
    
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
        GenericReviveInputViewController *vc = (GenericReviveInputViewController *)segue.destinationViewController;
        vc.conversation = localConversationArray[selectedIndexpath.row];
    }
}
@end
