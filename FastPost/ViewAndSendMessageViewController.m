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
    [self createTimer];
    [self fetchLocalMessage];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
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
        NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"createat" ascending:YES];
        fetchRequest.sortDescriptors = @[sort];
        [fetchRequest setFetchLimit:FETCH_COUNT];
    }
    
    //everytim this method is called, the fetchoffset is going to increase by FETCH_COUNT
    [fetchRequest setFetchOffset:fetchRequest.fetchOffset+FETCH_COUNT];
    
    
    NSError *fetchError;
    NSArray *results = [[SharedDataManager sharedInstance].managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
    if (!fetchRequest && results.count >0) {
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
            
            int numOfMissedMsg = 0;
            NSIndexPath *missedMessageIndexpath;
            
            NSMutableArray *indexPaths = [NSMutableArray array];
            int i =0;
            
            for (PFObject *object in objects) {
                
                Message *localMsg = [NSEntityDescription insertNewObjectForEntityForName:@"Message" inManagedObjectContext:[SharedDataManager sharedInstance].managedObjectContext];
                //if message has expired
                if ([((NSDate *)object[@"expirationDate"]) compare:[NSDate date]] != NSOrderedDescending) {
                    //create message for missed cell
                    numOfMissedMsg++;
                    localMsg.type = [NSNumber numberWithInt:MessageTypeMissed];
                    
                }else{
                    
                    localMsg.objectid = object[@"objectid"];
                    localMsg.content = object[@"content"];
                    localMsg.senderUsername = object[@"senderUsername"];
                    localMsg.createdat = object[@"createdat"];
                    localMsg.expirationDate = object[@"expirationDate"];
                    localMsg.participants = object[@"participants"];
                    [self.dataSource addObject:localMsg];
                    
                    NSIndexPath *index = [NSIndexPath indexPathForRow:i inSection:0];
                    [indexPaths addObject:index];
                    i++;
                }
            }
            //save message objects to db
            [[SharedDataManager sharedInstance] saveContext];
            //reload tableview
//            self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:uitableviewrowanimation
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
