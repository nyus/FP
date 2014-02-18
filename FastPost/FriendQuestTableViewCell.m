//
//  FriendQuestTableViewCell.m
//  FastPost
//
//  Created by Huang, Jason on 2/14/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "FriendQuestTableViewCell.h"

@implementation FriendQuestTableViewCell

-(id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.acceptButton.layer.cornerRadius = 4.0f;
        self.acceptButton.layer.borderColor = [[UIColor blueColor] CGColor];
        self.acceptButton.layer.borderWidth = 1.0f;
        self.notNowButton.layer.cornerRadius = 4.0f;
        self.notNowButton.layer.borderColor = [[UIColor blueColor] CGColor];
        self.notNowButton.layer.borderWidth = 1.0f;
    }
    
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)acceptButtonTapped:(id)sender {
    [self.delegate friendQuestTBCellAcceptButtonTappedWithCell:self];
}

- (IBAction)notNowButtonTapped:(id)sender {
    [self.delegate friendQuestTBCellNotNowButtonTappedWithCell:self];
}
@end
