//
//  Conversation.m
//  FastPost
//
//  Created by Sihang on 8/16/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "Conversation.h"


@implementation Conversation

@dynamic participants;
@dynamic objectid;
@dynamic lastUpdateDate;
@dynamic lastMessageContent;

-(NSString *)description{
    return [NSString stringWithFormat:@"participants: %@\nobjectid:%@\nlastUpdateDate:%@\nlastMessageContent:%@",self.participants,self.objectid,self.lastUpdateDate,self.lastMessageContent];
}
@end
