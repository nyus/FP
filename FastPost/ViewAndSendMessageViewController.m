//
//  ViewAndSendMessageViewController.m
//  FastPost
//
//  Created by Huang, Jason on 8/18/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "ViewAndSendMessageViewController.h"
#import <Parse/Parse.h>
#import "SharedDataManager.h"
static int FETCH_COUNT = 20;
@interface ViewAndSendMessageViewController(){
    //keep a reference to it becuase we want to access the fetchOffset
    NSFetchRequest *fetchRequest;
}
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSMutableArray *dataSource;
@end
@implementation ViewAndSendMessageViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    
    //this is for setting constraint in the parent vc. need to be set become becomeFirstResponder
    self.isFromPushSegue = YES;
    [self.enterMessageTextView becomeFirstResponder];
//    [self createTimer];
    [self fetchLocalMessage];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self fetchLocalMessage];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self destroyTimer];
}

-(void)createTimer{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(handletimerFired:) userInfo:nil repeats:YES];
}

-(void)destroyTimer{
    [self.timer invalidate];
    self.timer = nil;
}

-(void)handletimerFired:(NSTimer *)timer{
    [self fetchServerMessage];
}

-(void)fetchLocalMessage{
    if (!self.dataSource) {
        self.dataSource = [NSMutableArray array];
    }
    
    if (!fetchRequest) {
        fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Message"];
        NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"createdat" ascending:YES];
        fetchRequest.sortDescriptors = @[sort];
        [fetchRequest setFetchLimit:FETCH_COUNT];
    }
    
    //everytim this method is called, the fetchoffset is going to increase by FETCH_COUNT
    [fetchRequest setFetchOffset:self.dataSource.count];
    
    
    NSError *fetchError;
    NSArray *results = [[SharedDataManager sharedInstance].managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
    if (results.count >0) {
        [self.dataSource addObjectsFromArray:results];
    }
}

-(void)fetchServerMessage{
    //here fetch from parse
    PFQuery *query = [PFQuery queryWithClassName:@"Message"];
    [query whereKey:@"objectid" equalTo:self.conversation.objectid];
    [query orderByAscending:@"createdat"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error && objects.count!=0) {
            
            NSMutableArray *indexPathArray = [NSMutableArray array];
            int index = 0;
            for (int i = 0; i<objects.count; i++) {
                
                int start = i;
                while (start<objects.count &&
                       [(NSDate *)([[objects objectAtIndex:start] valueForKey:@"expirationDate"]) compare:[NSDate date]] == NSOrderedDescending) {
                    start++;
                }
                
                PFObject *message = objects[i];
                Message *localMsg = [NSEntityDescription insertNewObjectForEntityForName:@"Message" inManagedObjectContext:[SharedDataManager sharedInstance].managedObjectContext];
                NSIndexPath *indexpath = [NSIndexPath indexPathForRow:index inSection:0];
                //while loop content doesnt get executed
                if(start == i){
                    //
                    localMsg.objectid = message[@"objectid"];
                    localMsg.content = message[@"content"];
                    localMsg.senderUsername = message[@"senderUsername"];
                    localMsg.createdat = message[@"createdat"];
                    localMsg.expirationDate = message[@"expirationDate"];
                    localMsg.participants = message[@"participants"];

                }else{
                    localMsg.type = [NSNumber numberWithInt:MessageTypeMissed];
                    localMsg.numOfMissedMsgs = [NSNumber numberWithInt:start-i];
                }
                
                [indexPathArray addObject:indexpath];
                [self.dataSource addObject:localMsg];
                
                if (i==start) {
                    i++;
                }else{
                    i=start;
                }
                
                index++;
            }
            
            //save message objects to db
            [[SharedDataManager sharedInstance] saveContext];
            //reload tableview
            [self.tableView insertRowsAtIndexPaths:indexPathArray withRowAnimation:UITableViewRowAnimationAutomatic];
            //scroll to visible
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.dataSource.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            
        }
    }];
}

#pragma mark - UITableViewDelegate

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 0;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    return nil;
}

@end
