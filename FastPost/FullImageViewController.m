//
//  FullImageViewController.m
//  FastPost
//
//  Created by Sihang on 7/2/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "FullImageViewController.h"
#import "ZoomCollectionViewCell.h"
#import <Parse/Parse.h>
@interface FullImageViewController ()<UICollectionViewDataSource,UICollectionViewDelegate>
@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, strong) NSMutableDictionary *isLoadingFile;
@end

@implementation FullImageViewController

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
    self.dataSource = [NSMutableArray arrayWithCapacity:1];
    [self.dataSource addObject:@"toShowDummyCell"];
    [self.collectionView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setUsername:(NSString *)username{
    _username = username;
    
    PFQuery *query = [[PFQuery alloc] initWithClassName:@"Photo"];
    [query whereKey:@"username" equalTo:username];
    [query whereKey:@"isHighRes" equalTo:@YES];
    query.limit = 3;//only grab the most recent avatars
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error && objects.count!=0) {
            if(self.dataSource){
                [self.dataSource removeAllObjects];
            }
            self.dataSource = [[NSMutableArray alloc] initWithArray:objects];
            self.isLoadingFile = [NSMutableDictionary dictionaryWithCapacity:objects.count];
            [self.collectionView reloadData];
        }
    }];
}

#pragma mark - UICollectionViewDelegate
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.dataSource.count;
}
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    ZoomCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    
    [cell showProgressIndicator];
    id object = self.dataSource[indexPath.row];
    if ([object isKindOfClass:[UIImage class]]) {
        cell.imageVIew.image = object;
        [cell hideProgressIndicator];
    }else if ([object isKindOfClass:[PFObject class]]){
        
        cell.imageVIew.image = nil;
        if (!collectionView.isDragging && !collectionView.isDecelerating) {
            [self loadHighResPhotoForIndexPath:indexPath];
        }
    }
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath{
    [self cancelImageDownloadForCellAtIndexPath:indexPath];
}

#pragma mark - uiscrollviewdelegate

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
//    NSLog(@"%@",[self.collectionView indexPathsForVisibleItems]);
    for (NSIndexPath *path in [self.collectionView indexPathsForVisibleItems]) {
        [self loadHighResPhotoForIndexPath:path];
    }
}

#pragma mark - Helper

-(void)cancelImageDownloadForCellAtIndexPath:(NSIndexPath *)indexPath{
    id object = self.dataSource[indexPath.row];
    
    if ([object isKindOfClass:[PFObject class]] && [[self.isLoadingFile objectForKey:indexPath] intValue] == 1) {
        PFFile *file = (PFFile *)object[@"image"];
        [file cancel];
        [self.isLoadingFile setObject:@0 forKey:indexPath];
    }
}

-(void)loadHighResPhotoForIndexPath:(NSIndexPath *)indexPath{
    
    id object = self.dataSource[indexPath.row];
    
    if ([object isKindOfClass:[UIImage class]]) {
        return;
    }else if ([object isKindOfClass:[PFObject class]]){
        PFFile *file = (PFFile *)object[@"image"];
        __block ZoomCollectionViewCell *cell = (ZoomCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        
        if (!cell) {
            return;
        }
        
        if (![self.isLoadingFile objectForKey:indexPath] && [[self.isLoadingFile objectForKey:indexPath] intValue] == 1) {
            return;
        }
        
        [self.isLoadingFile setObject:@1 forKey:indexPath];
        [cell showProgressIndicator];
        
        [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            if (!error && data) {
                UIImage *image = [UIImage imageWithData:data];
                [self.dataSource replaceObjectAtIndex:indexPath.row withObject:image];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    cell.imageVIew.image = image;
                    [cell hideProgressIndicator];
                });
            }
        }];
    }
}
@end
