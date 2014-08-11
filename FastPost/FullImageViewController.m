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
@interface FullImageViewController ()<UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout>
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
    
    UIButton *done = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width-20-44, 20, 56, 30)];
    [done setTitle:@"Done" forState:UIControlStateNormal];
    [done setTitleColor:[UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
    done.layer.borderColor =[[UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0] CGColor];
    done.layer.borderWidth = 1.0f;
    done.layer.cornerRadius = 2.0f;
    [done addTarget:self action:@selector(dismissSelf) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:done];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dismissSelf{
    [self dismissViewControllerAnimated:YES completion:nil];
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
    
    //when an image is fetched from the server, we replace the parse object at this index path with the corresponding UIImage
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

#pragma mark -- UICollectionViewDelegateFlowLayout

//overwriting this method explicitely makes auto layout constraints work properly
-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    return CGSizeMake(collectionView.frame.size.width, collectionView.frame.size.height);
}

#pragma mark - uiscrollviewdelegate

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{

    for (NSIndexPath *path in [self.collectionView indexPathsForVisibleItems]) {
        [self loadHighResPhotoForIndexPath:path];
    }
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if (decelerate==NO) {
        for (NSIndexPath *path in [self.collectionView indexPathsForVisibleItems]) {
            [self loadHighResPhotoForIndexPath:path];
        }
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
        
        if (![self.isLoadingFile objectForKey:indexPath] && [[self.isLoadingFile objectForKey:indexPath] intValue] == 1) {
            return;
        }
        
        __block ZoomCollectionViewCell *cell = (ZoomCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        [self.isLoadingFile setObject:@1 forKey:indexPath];
        [cell showProgressIndicator];
        
        [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            if (!error && data) {
                
                ZoomCollectionViewCell *cell = (ZoomCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
                
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
