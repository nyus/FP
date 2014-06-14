//
//  BaseViewControllerWithStatusTableView.m
//  FastPost
//
//  Created by Sihang Huang on 1/14/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "BaseViewControllerWithStatusTableView.h"
#import <Parse/Parse.h>
#import "Helper.h"
#import "Status.h"
#import "FPLogger.h"
#define BACKGROUND_CELL_HEIGHT 300.0f
#define ORIGIN_Y_CELL_MESSAGE_LABEL 76.0f
#define CELL_MESSAGE_LABEL_WIDTH 280.0f
@interface BaseViewControllerWithStatusTableView (){

    //cache calculated label height
    NSMapTable *labelHeightMap;
    //cache is there photo
    NSMapTable *isTherePhotoMap;
    //cache cell height
    NSMapTable *cellHeightMap;
}

@end

@implementation BaseViewControllerWithStatusTableView

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
    labelHeightMap = [NSMapTable strongToStrongObjectsMapTable];
    isTherePhotoMap = [NSMapTable strongToStrongObjectsMapTable];
    cellHeightMap = [NSMapTable strongToStrongObjectsMapTable];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{   
    StatusTableViewCell *cell = nil;
    Status *status = self.dataSource[indexPath.row];
    PFFile *picture = (PFFile *)status.picture;
    
    if (picture == (PFFile *)[NSNull null] || picture == nil) {
        
        cell = [tableView dequeueReusableCellWithIdentifier:@"messageCell" forIndexPath:indexPath];
        
    }else{
        cell = [tableView dequeueReusableCellWithIdentifier:@"messageAndPhotoCell" forIndexPath:indexPath];
    
        //get image
        PFFile *picture = (PFFile *)[status picture];
        //add spinner on image view to indicate pulling image
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        spinner.center = CGPointMake((int)cell.statusCellPhotoImageView.frame.size.width/2, (int)cell.statusCellPhotoImageView.frame.size.height/2);
        [cell.statusCellPhotoImageView addSubview:spinner];
        [spinner startAnimating];
        [picture getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            if (data && !error) {
                cell.statusCellPhotoImageView.image = [UIImage imageWithData:data];
            }else{
                [FPLogger record:[NSString stringWithFormat:@"error (%@) getting status photo with status id %@",error.localizedDescription,status.objectid]];
                NSLog(@"error (%@) getting status photo with status id %@",error.localizedDescription,status.objectid);
            }
            
            [spinner stopAnimating];
        }];
    }
    
    // Configure the cell...
    cell.delegate = self;
    //pass a reference so in statusTableViewCell can use status.hash to access stuff
    cell.status = status;
    
    //message
    cell.statusCellMessageLabel.text = status.message;
    
    //username
    cell.statusCellUsernameLabel.text = status.posterUsername;
    cell.userNameButton.titleLabel.text = nil;
    
    //revivable button
    if (status.revivable.boolValue) {
        [cell enableRevivePressHoldGesture];
    }else{
        [cell disableRevivePressHoldGesture];
    }

    //cell date
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm MM/dd/yy"];
    NSString *str = [formatter stringFromDate:[status updatedAt]];
    cell.statusCellDateLabel.text = str;
    
    //like count
    cell.reviveCountLabel.text = status.reviveCount.stringValue;
    
    //comment count
    cell.commentCountLabel.text = status.commentCount.stringValue;
    
    //get avatar
    [Helper getAvatarForUser:status.posterUsername avatarType:AvatarTypeMid forImageView:cell.statusCellAvatarImageView];
    
    return cell;
}

//-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
//    StatusTableViewCell *c = (StatusTableViewCell *)cell;
//    c.indexPath = indexPath;
//    
//}

-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 200;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(!self.dataSource || self.dataSource.count == 0){
        return BACKGROUND_CELL_HEIGHT;
    }else{
        
        Status *status = self.dataSource[indexPath.row];
        NSString *key =[NSString stringWithFormat:@"%lu",(unsigned long)status.hash];
//        NSLog(@"indexPath:%@",indexPath);
        //is cell height has been calculated, return it
        if ([cellHeightMap objectForKey:key]) {
//            NSLog(@"return stored cell height: %f",[[cellHeightMap objectForKey:key] floatValue]);
            return [[cellHeightMap objectForKey:key] floatValue];
            
        }else{
            
            //determine height of label(message must exist)
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 280, 20)];
            //number of lines must be set to zero so that sizeToFit would work correctly
            label.numberOfLines = 0;
            label.font = [UIFont fontWithName:@"AvenirNextCondensed-Regular" size:17];
            label.text = [status message];
            CGSize aSize = [label sizeThatFits:label.frame.size];
//            NSLog(@"aSize is %@",NSStringFromCGSize(aSize));

            float labelHeight = aSize.height;//ceilf(ceilf(size.width) / CELL_MESSAGE_LABEL_WIDTH)*ceilf(size.height)+10;
            [labelHeightMap setObject:[NSNumber numberWithFloat:labelHeight] forKey:key];
            
            
            //determine if there is a picture
            float pictureHeight = 0;;
            PFFile *picture = (PFFile *)status.picture;
            if (picture == (PFFile *)[NSNull null] || picture == nil) {
                
                [isTherePhotoMap setObject:[NSNumber numberWithBool:NO] forKey:key];
                pictureHeight = 0;
                
            }else{
                
                //204 height of picture image view
                [isTherePhotoMap setObject:[NSNumber numberWithBool:YES] forKey:key];
                pictureHeight = 204;
                
            }
            
            float cellHeight = ORIGIN_Y_CELL_MESSAGE_LABEL + labelHeight;
            if (pictureHeight !=0) {
                cellHeight += 10 + pictureHeight;
            }
            
            cellHeight = cellHeight+10;
            
            [cellHeightMap setObject:[NSNumber numberWithFloat:cellHeight]
                              forKey:key];
            return cellHeight;
        }
    }
}

-(void)removeStoredHeightForStatus:(Status *)status{
    NSString *key =[NSString stringWithFormat:@"%d",status.hash];
    [cellHeightMap removeObjectForKey:key];
}
@end
