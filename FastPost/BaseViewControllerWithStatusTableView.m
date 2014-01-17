//
//  BaseViewControllerWithStatusTableView.m
//  FastPost
//
//  Created by Sihang Huang on 1/14/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "BaseViewControllerWithStatusTableView.h"
#import <Parse/Parse.h>
#import "Helper.h"
#import "Status.h"
#define BACKGROUND_CELL_HEIGHT 300.0f
#define ORIGIN_Y_CELL_MESSAGE_LABEL 86.0f

@interface BaseViewControllerWithStatusTableView ()

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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *CellIdentifier = @"Cell";
    StatusTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.delegate = self;
    // Configure the cell...
    cell.statusCellMessageLabel.text = [[self.dataSource objectAtIndex:indexPath.row] pfObject][@"message"];
    cell.statusCellUsernameLabel.text = [[[self.dataSource objectAtIndex:indexPath.row] pfObject] objectForKey:@"posterUsername"];
    BOOL revivable = [[self.dataSource[indexPath.row] pfObject][@"revivable"] boolValue];
    if (!revivable) {
        cell.statusCellReviveButton.hidden = YES;
    }
    //
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm MM/dd/yy"];
    NSString *str = [formatter stringFromDate:[[self.dataSource objectAtIndex:indexPath.row] pfObject].updatedAt];
    cell.statusCellDateLabel.text = str;
    
    //get avatar
    [Helper getAvatarForSelfOnImageView:cell.statusCellAvatarImageView];
    
    PFFile *picture = [[[self.dataSource objectAtIndex:indexPath.row] pfObject] objectForKey:@"picture"];
    if (picture != (PFFile *)[NSNull null] && picture != nil) {
        
        //add spinner on image view to indicate pulling image
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        spinner.center = CGPointMake((int)cell.statusCellPhotoImageView.frame.size.width/2, (int)cell.statusCellPhotoImageView.frame.size.height/2);
        [cell.statusCellPhotoImageView addSubview:spinner];
        [spinner startAnimating];
        
        [picture getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            
            if (data && !error) {
                cell.statusCellPhotoImageView.image = [UIImage imageWithData:data];
            }else{
                NSLog(@"error (%@) getting status photo with status id %@",error.localizedDescription,[[[self.dataSource objectAtIndex:indexPath.row] pfObject] objectId]);
            }
            
            [spinner stopAnimating];
        }];
    }
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if(!self.dataSource || self.dataSource.count == 0){
        return BACKGROUND_CELL_HEIGHT;
    }else{
        
        //determine height of label
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 280, 20)];
        //number of lines must be set to zero so that sizeToFit would work correctly
        label.numberOfLines = 0;
        label.font = [UIFont fontWithName:@"AvenirNextCondensed-Regular" size:17];
        label.text = [self.dataSource[indexPath.row] pfObject][@"message"];
        [label sizeToFit];
        
        //determine if there is a picture
        
        PFFile *picture = [[[self.dataSource objectAtIndex:indexPath.row] pfObject] objectForKey:@"picture"];
        if (picture == (PFFile *)[NSNull null] || picture == nil) {
            //68 y origin of label
            return ORIGIN_Y_CELL_MESSAGE_LABEL + label.frame.size.height + 10;
        }else{
            //68 y origin of label, 204 height of picture image view
            return ORIGIN_Y_CELL_MESSAGE_LABEL + label.frame.size.height + 10 + 204 + 10;
        }
        
    }
}
@end
