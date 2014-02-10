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
#import <Parse/Parse.h>
@interface MessageTableViewViewController ()<UITableViewDataSource,UITableViewDelegate>{
    NSMutableArray *dataSource;

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
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)fetchMessage{
    
    if (dataSource) {
        dataSource = [NSMutableArray array];
    }
#warning need to cache result
    PFQuery *query = [[PFQuery alloc] initWithClassName:@"Message"];
    [query whereKey:@"receiver" equalTo:[PFUser currentUser].username];
    [query whereKey:@"read" equalTo:[NSNumber numberWithBool:NO]];
    
    //load first 100 messages at startup, if need more, load more, this parameter will stop parse from fetching redundant messages
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"lastFetchedMsgCount"]) {
        query.skip = [[[NSUserDefaults standardUserDefaults] objectForKey:@"lastFetchedMsgCount"] intValue];
    }
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error && objects) {
            
            for (PFObject *object in objects) {
                Message *message = [NSEntityDescription insertNewObjectForEntityForName:@"Message" inManagedObjectContext:[SharedDataManager sharedInstance].managedObjectContext];
                message.createdAt = object.createdAt;
                message.updatedAt = object.updatedAt;
                message.message = object[@"message"];
                message.senderUsername = object[@"senderUsername"];
                message.receiverUsername = object[@"receiverUsername"];
                message.read = object[@"read"];
                message.objectid = object.objectId;
                
                [dataSource addObject:message];
            }
            [[SharedDataManager sharedInstance] saveContext];
            
            //if not enough new message, then load some old messages in the database
            if (objects.count < 20) {
                
                NSArray *fetchResult = [self fetchMessageFromLocalDatabaseWithCount:(int)(20-objects.count) andOffSet:0];
                for (Message *message in fetchResult) {
                    [dataSource addObject:message];
                }
                
                //this is for reload. do not want to fetch already fetched objects
                if (fetchResult!=nil) {
                    //update only if the local fetch is successful
                    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:(int)(20-objects.count)] forKey:@"lastFetchedMsgCount"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
            }
            
            //reload
            [self.tableView reloadData];
            
        }else{
            
            //encouter fetch error, load message from the data base
            NSArray *fetchResult = [self fetchMessageFromLocalDatabaseWithCount:20 andOffSet:0];
            for (Message *message in fetchResult) {
                [dataSource addObject:message];
            }
            
            [self.tableView reloadData];
        }
    }];
}

#pragma mark - core data fetch 

-(NSArray *)fetchMessageFromLocalDatabaseWithCount:(int)count andOffSet:(int)offset{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Message"];
    [request setFetchLimit:count];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]
                                        initWithKey:@"createAt" ascending:NO];
    [request setSortDescriptors:@[sortDescriptor]];
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
    return 0;
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
    [Helper getAvatarForUser:[dataSource[indexPath.row] objectForKey:@"senderUsername"] forImageView:cell.msgCellProfileImageView];
    //sender name
    cell.msgCellUsernameLabel.text = [dataSource[indexPath.row] objectForKey:@"senderUsername"];
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

- (IBAction)composeNewMessageButtonTapped:(id)sender {
    
}
@end
