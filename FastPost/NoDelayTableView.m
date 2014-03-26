//
//  NoDelayTableView.m
//  FastPost
//
//  Created by Sihang Huang on 3/25/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "NoDelayTableView.h"

@implementation NoDelayTableView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/
-(BOOL)touchesShouldCancelInContentView:(UIView *)view{
    if ([view isKindOfClass:[UIButton class]]) {
        return NO;
    }else{
        return YES;
    }
    
}
@end
