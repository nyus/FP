//
//  NoDelayButton.m
//  FastPost
//
//  Created by Sihang Huang on 3/25/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "NoDelayButton.h"

@implementation NoDelayButton

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

-(void)setSelected:(BOOL)selected{
    if (selected) {
        self.titleLabel.textColor = [UIColor grayColor];
    }else{
        self.titleLabel.textColor = [UIColor colorWithRed:27.0/255.0 green:117.0/255.0 blue:223.0/255.0 alpha:1];
    }
}

-(void)setHighlighted:(BOOL)highlighted{
    if (highlighted) {
        self.titleLabel.textColor = [UIColor grayColor];
    }else{
        self.titleLabel.textColor = [UIColor colorWithRed:27.0/255.0 green:117.0/255.0 blue:223.0/255.0 alpha:1];
    }
}

@end
