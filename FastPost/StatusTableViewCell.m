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
@interface StatusTableViewCell(){
    BOOL pressAndHoldRecognized;
    PressAndHoldGesture *pressHoldGesture;
    UISwipeGestureRecognizer *swipteGesture;
    UITapGestureRecognizer *tap;
}

@end

@implementation StatusTableViewCell

-(id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        swipteGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
        swipteGesture.direction = UISwipeGestureRecognizerDirectionLeft;
        [self addGestureRecognizer:swipteGesture];
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

-(void)handleSwipe:(UISwipeGestureRecognizer *)swipe{
    [self.delegate swipeGestureRecognizedOnCell:self];
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
