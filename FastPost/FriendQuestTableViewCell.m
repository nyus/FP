//
//  FriendQuestTableViewCell.m
//  FastPost
//
//  Created by Huang, Jason on 2/14/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "FriendQuestTableViewCell.h"

@implementation FriendQuestTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
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

- (IBAction)declineButtonTapped:(id)sender {
    [self.delegate friendQuestTBCellDeclineButtonTappedWithCell:self];
}
@end
