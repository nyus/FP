//
//  StatusTableCell.m
//  FastPost
//
//  Created by Huang, Sihang on 11/25/13.
//  Copyright (c) 2013 Huang, Sihang. All rights reserved.
//

#import "StatusTableViewCell.h"
#import "UIImage+ImageEffects.h"
#import "Status.h"
#import "PressAndHoldGesture.h"
#import "ImageCollectionViewCell.h"
#import <Parse/Parse.h>
#define REVIVE_PROGRESS_VIEW_INIT_ALPHA .7f
#define PROGRESSION_RATE 1
#define TRESHOLD 60.0f
@interface StatusTableViewCell(){
    BOOL pressAndHoldRecognized;
    PressAndHoldGesture *pressHoldGesture;
    UISwipeGestureRecognizer *leftSwipteGesture;
    UISwipeGestureRecognizer *rightSwipteGesture;
    UITapGestureRecognizer *tap;
    UIPanGestureRecognizer *pan;
    float x;
}

@end

@implementation StatusTableViewCell

-(id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        leftSwipteGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleLeftSwipe:)];
        leftSwipteGesture.direction = UISwipeGestureRecognizerDirectionLeft;
        [self addGestureRecognizer:leftSwipteGesture];
        
        rightSwipteGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleRightSwipe:)];
        rightSwipteGesture.direction = UISwipeGestureRecognizerDirectionRight;
        [self addGestureRecognizer:rightSwipteGesture];
        
        tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
        [self addGestureRecognizer:tap];
    }
    
    return self;
}

- (IBAction)commentButtonTapped:(id)sender {
    [self.delegate commentButtonTappedOnCell:self];
}

-(void)disableRevivePressHoldGesture{
    if (pressHoldGesture) {
        [self removeGestureRecognizer:pressHoldGesture];
        pressHoldGesture = nil;
    }
}

-(void)enableRevivePressHoldGesture{
    if (!pressHoldGesture) {
        pressHoldGesture = [[PressAndHoldGesture alloc] initWithTarget:self action:@selector(handlePressAndHold:)];
        [self addGestureRecognizer:pressHoldGesture];
    }
}

-(void)handlePressAndHold:(PressAndHoldGesture *)gesture{
    if (gesture.state == UIGestureRecognizerStateEnded || (gesture.state == UIGestureRecognizerStateCancelled && pressAndHoldRecognized)) {
        pressAndHoldRecognized =NO;
        float reviveProgressViewMaxX =CGRectGetMaxX(self.reviveProgressView.frame);
        //send out delegating message so that can add more time to the post
        [UIView animateKeyframesWithDuration:.5 delay:0 options:UIViewKeyframeAnimationOptionCalculationModeLinear animations:^{
            [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:.1 animations:^{
                self.reviveProgressView.alpha = 1.0f;
            }];
            [UIView addKeyframeWithRelativeStartTime:.1 relativeDuration:.2 animations:^{
                self.reviveProgressView.alpha = 0.5f;
            }];
            [UIView addKeyframeWithRelativeStartTime:.2 relativeDuration:.3 animations:^{
                self.reviveProgressView.alpha = 1.0f;
            }];
            [UIView addKeyframeWithRelativeStartTime:.3 relativeDuration:.5 animations:^{
                self.reviveProgressView.alpha = 0.0f;
            }];
        } completion:^(BOOL finished) {
            self.reviveProgressView.center = CGPointMake(-self.contentView.center.x, self.reviveProgressView.center.y);
            self.reviveProgressView.alpha = REVIVE_PROGRESS_VIEW_INIT_ALPHA;
            [self.delegate reviveAnimationDidEndOnCell:self withProgress:reviveProgressViewMaxX/self.frame.size.width];
        }];
    }else if ( (gesture.state == UIGestureRecognizerStateCancelled && !pressAndHoldRecognized) || gesture.state == UIGestureRecognizerStateFailed){
        pressAndHoldRecognized =NO;
        [UIView animateWithDuration:.3 animations:^{
            self.reviveProgressView.center = CGPointMake(-self.contentView.center.x, self.reviveProgressView.center.y);
        } completion:^(BOOL finished) {
            self.reviveProgressView.alpha = REVIVE_PROGRESS_VIEW_INIT_ALPHA;
        }];
    }else{
        if(self.reviveProgressView.center.x <= self.contentView.center.x){
            self.reviveProgressView.center = CGPointMake(self.reviveProgressView.center.x+PROGRESSION_RATE, self.reviveProgressView.center.y);
        }else{
            
            //setting enabled to NO makes the gesture fall to Canceled state, but in this case it's recognized.
            pressAndHoldRecognized = YES;
            //cancel for this recognition
            gesture.enabled = NO;
            //enable for next recognition
            gesture.enabled = YES;
        }
    }
}

-(void)closeCell{
    
    if ([self isCellOpen]) {
        [self enableButtonsOnCell:YES];
        [UIView animateWithDuration:.3 animations:^{
            self.contentContainerView.frame = CGRectMake(0,
                                                         self.contentContainerView.frame.origin.y,
                                                         self.contentContainerView.frame.size.width,
                                                         self.contentContainerView.frame.size.height);
        }];
    }
}

-(void)openCell{
    
    if ([self isCellOpen]==NO) {
        [self enableButtonsOnCell:NO];
        [UIView animateWithDuration:.3 animations:^{
            self.contentContainerView.center = CGPointMake(self.contentContainerView.center.x + TRESHOLD, self.contentContainerView.center.y);
        }];
    }
}

-(void)handleLeftSwipe:(UISwipeGestureRecognizer *)swipe{
    
    if ([self isCellOpen]) {
        [self closeCell];
    }else{
        [self.delegate swipeGestureRecognizedOnCell:self];
    }
}

-(void)handleRightSwipe:(UISwipeGestureRecognizer *)swipe{
    [self openCell];
}

-(void)handleTapGesture:(UITapGestureRecognizer *)tap{
    if ([self isCellOpen]) {
        [self closeCell];
    }
}

-(BOOL)isCellOpen{
    return self.contentContainerView.frame.origin.x!=0;
}

-(void)enableButtonsOnCell:(BOOL)enable{
    self.avatarButton.userInteractionEnabled = enable;
    self.userNameButton.userInteractionEnabled = enable;
    self.commentButton.userInteractionEnabled = enable;
}

#pragma mark - uicollectionview delegate

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.collectionViewImagesArray.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    ImageCollectionViewCell *cell = (ImageCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.imageView.image = self.collectionViewImagesArray[indexPath.row];
    return cell;
}
@end
