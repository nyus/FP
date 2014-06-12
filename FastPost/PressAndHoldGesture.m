//
//  PressAndHoldGesture.m
//  asdfasdf
//
//  Created by Sihang Huang on 6/11/14.
//  Copyright (c) 2014 Sihang Huang. All rights reserved.
//

#import "PressAndHoldGesture.h"
#import <UIKit/UIGestureRecognizerSubclass.h>
@interface PressAndHoldGesture(){
    double cur;
}
@property (nonatomic, strong) NSTimer *timer;
@end
@implementation PressAndHoldGesture
- (void)reset{
    [self.timer invalidate];
    self.timer = nil;
}
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [super touchesBegan:touches withEvent:event];
    if (touches.count!=1) {
        self.state = UIGestureRecognizerStateFailed;
    }else{
        cur = CACurrentMediaTime();
        if (!self.timer) {
            self.timer = [NSTimer scheduledTimerWithTimeInterval:1/30 target:self selector:@selector(handleTimer) userInfo:nil repeats:YES];
        }
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    self.state = UIGestureRecognizerStateFailed;
    [self reset];
        NSLog(@"failed");
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    if (CACurrentMediaTime()-cur < 0.2) {
        self.state = UIGestureRecognizerStateFailed;
        NSLog(@"failed");
    }else{
        self.state = UIGestureRecognizerStateEnded;
        NSLog(@"ended");
    }
    
    [self reset];
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event{
    self.state = UIGestureRecognizerStateCancelled;
    [self reset];
        NSLog(@"cancelled");
}

-(void)handleTimer{
    if (CACurrentMediaTime()-cur < 0.2) {
        return;
    }
    self.state = UIGestureRecognizerStateChanged;
}
@end
