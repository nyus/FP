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
#define BACKGROUND_CELL_HEIGHT 300.0f
#define ORIGIN_Y_CELL_MESSAGE_LABEL 76.0f
#define CELL_MESSAGE_LABEL_WIDTH 280.0f
#define CELL_BUTTONS_CONTAINER_HEIGHT 44.0f
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
    //    if(!dataSource){
    //        //return background cell
    //        return 1;
    //    }else{
    // Return the number of rows in the section.
    return self.dataSource.count;
    //    }
}

//hides the liine separtors when data source has 0 objects
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] init];
    
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    Status *status = self.dataSource[indexPath.row];
    NSString *key =[NSString stringWithFormat:@"%d",status.hash];
    
    static NSString *CellIdentifier = @"Cell";
    StatusTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    // Configure the cell...
    cell.delegate = self;
    cell.needSocialButtons = self.needSocialButtons;
    //pass a reference so in statusTableViewCell can use status.hash to access stuff
    cell.status = status;
    
    //message
    cell.statusCellMessageLabel.text = [status message];
    
    //username
    cell.statusCellUsernameLabel.text = [status posterUsername];
    
    //revivable button
    BOOL revivable = [[status revivable] boolValue];
    if (!revivable) {
        cell.statusCellReviveButton.hidden = YES;
    }else{
        cell.statusCellReviveButton.hidden = NO;
    }
    
    //cell date
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm MM/dd/yy"];
    NSString *str = [formatter stringFromDate:[status updatedAt]];
    cell.statusCellDateLabel.text = str;
    
    //get avatar
    [Helper getAvatarForSelfOnImageView:cell.statusCellAvatarImageView];
    
    //picture
    if ([[isTherePhotoMap objectForKey:key] boolValue]) {
        
        cell.statusCellPhotoImageView.hidden = NO;

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
                NSLog(@"error (%@) getting status photo with status id %@",error.localizedDescription,status.objectid);
            }
            
            [spinner stopAnimating];
        }];
    }else{
        cell.statusCellPhotoImageView.hidden = YES;
    }
    
    //social buttons
    if (self.needSocialButtons) {
        cell.likeCountLabel.text = [[status likeCount] stringValue];
        cell.commentCountLabel.text = [[status likeCount] stringValue];
    }
    
    //passing reference
    cell.isTherePhotoMap = isTherePhotoMap;
    cell.labelHeightMap = labelHeightMap;
    cell.indexPath = indexPath;

    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    StatusTableViewCell *c = (StatusTableViewCell *)cell;
    c.indexPath = indexPath;
    
}

-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 200;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{

    if(!self.dataSource || self.dataSource.count == 0){
        return BACKGROUND_CELL_HEIGHT;
    }else{

        Status *status = self.dataSource[indexPath.row];
        NSString *key =[NSString stringWithFormat:@"%d",status.hash];
        NSLog(@"indexPath:%@",indexPath);
        //is cell height has been calculated, return it
        if ([cellHeightMap objectForKey:key]) {
            NSLog(@"return stored cell height: %f",[[cellHeightMap objectForKey:key] floatValue]);
            return [[cellHeightMap objectForKey:key] floatValue];
            
        }else{
            
            //determine height of label(message must exist)
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 280, 20)];
            //number of lines must be set to zero so that sizeToFit would work correctly
            label.numberOfLines = 0;
            label.font = [UIFont fontWithName:@"AvenirNextCondensed-Regular" size:17];
            label.text = [status message];
            CGSize aSize = [label sizeThatFits:label.frame.size];
            NSLog(@"aSize is %@",NSStringFromCGSize(aSize));
            
//            CGSize size = [label.text sizeWithAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"AvenirNextCondensed-Regular" size:17]}];
//            NSLog(@"size is %@",NSStringFromCGSize(size));
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
            
            if(self.needSocialButtons){
                //this container view has like, comment, revive buttons
                cellHeight += 10 + CELL_BUTTONS_CONTAINER_HEIGHT;
            }
            
            //cell line separator is on the 10th pixel. so +11.
            cellHeight = cellHeight+11;
            
            [cellHeightMap setObject:[NSNumber numberWithFloat:cellHeight]
                              forKey:key];
            return cellHeight;
        }
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)removeStoredHeightForStatus:(Status *)status{
    NSString *key =[NSString stringWithFormat:@"%d",status.hash];
    [cellHeightMap removeObjectForKey:key];
}
@end
