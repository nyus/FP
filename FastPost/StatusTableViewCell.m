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
#define REVIVE_PROGRESS_VIEW_INIT_ALPHA .5f
@interface StatusTableViewCell(){
    BOOL pressAndHoldRecognized;
    PressAndHoldGesture *pressHoldGesture;
}
@end

@implementation StatusTableViewCell


-(id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self.statusCellUsernameLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(usernameLabelTapped:)]];
        //turn off autolayout on the cells
        self.statusCellMessageLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.statusCellPhotoImageView.translatesAutoresizingMaskIntoConstraints = NO;
        
    }
    
    return self;
}


- (IBAction)userNameTapped:(id)sender {
    [self.delegate usernameLabelTappedOnCell:self];
}

-(void)usernameLabelTapped:(UITapGestureRecognizer *)tap{
    [self.delegate usernameLabelTappedOnCell:self];
}

- (IBAction)likeButtonTapped:(id)sender {
    [self.delegate likeButtonTappedOnCell:self];
}

- (IBAction)commentButtonTapped:(id)sender {
    [self.delegate commentButtonTappedOnCell:self];
}

-(void)disableRevivePressHoldGesture{
    if (pressHoldGesture) {
        [self removeGestureRecognizer:pressHoldGesture];
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
            self.reviveProgressView.center = CGPointMake(self.reviveProgressView.center.x+0.07, self.reviveProgressView.center.y);
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

/*
-(void)blurCell{

    if (!self.blurImageView.image) {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            UIGraphicsBeginImageContext(self.bounds.size);
            [self.layer renderInContext:UIGraphicsGetCurrentContext()];
            UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();

            CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
            [blurFilter setDefaults];

            CIImage *imageToBlur = [CIImage imageWithCGImage:image.CGImage];
            [blurFilter setValue:imageToBlur forKey:kCIInputImageKey];
            [blurFilter setValue:@3.0 forKey:@"inputRadius"];

            CIImage *outputImage = blurFilter.outputImage;

            dispatch_queue_t main = dispatch_get_main_queue();
            dispatch_sync(main, ^{
                self.blurImageView.image = [UIImage imageWithCIImage:outputImage];
            });
        });


    }

    self.blurImageView.hidden = NO;

    CGRect newFrame = self.containerView.frame;
    newFrame.origin = CGPointMake(-newFrame.size.width/2, newFrame.origin.y);
    [UIView animateWithDuration:.3 animations:^{
        self.containerView.frame = newFrame;
    }];
}
*/

@end
