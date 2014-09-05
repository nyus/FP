//
//  Message.m
//  FastPost
//
//  Created by Sihang on 9/2/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "Message.h"

@implementation Message

@dynamic content;
@dynamic countDown;
@dynamic createdat;
@dynamic expirationDate;
@dynamic expirationTimeInSec;
@dynamic numOfMissedMsgs;
@dynamic objectid;
@dynamic participants;
@dynamic read;
@dynamic receiverUsername;
@dynamic senderUsername;
@dynamic type;
@dynamic updatedat;
@dynamic messageCellHeight;
-(NSString *)description{
    return [NSString stringWithFormat:@" content:%@\n createdat:%@\n expirationDate:%@\n numOfMissedMsgs:%@\n objectid:%@\n participants:%@\n receiverUsername:%@\n senderUsername:%@\n type:%@\n updatedat:%@\n",self.content,self.createdat,self.expirationDate,self.numOfMissedMsgs,self.objectid,self.participants,self.receiverUsername,self.senderUsername,self.type,self.updatedat];
}
@end
