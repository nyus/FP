//
//  Message.h
//  FastPost
//
//  Created by Sihang on 9/2/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
NS_ENUM(NSUInteger, MessageType){
    MessageTypeRegular,
    MessageTypeMissed
};

@interface Message : NSManagedObject

@property (nonatomic, retain) NSString * content;
@property (nonatomic, retain) NSNumber * countDown;
@property (nonatomic, retain) NSDate * createdat;
@property (nonatomic, retain) NSDate * expirationDate;
@property (nonatomic, retain) NSNumber * expirationTimeInSec;
@property (nonatomic, retain) NSNumber * numOfMissedMsgs;
@property (nonatomic, retain) NSString * objectid;
@property (nonatomic, retain) id participants;
@property (nonatomic, retain) NSNumber * read;
@property (nonatomic, retain) NSString * receiverUsername;
@property (nonatomic, retain) NSString * senderUsername;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSDate * updatedat;
@property (nonatomic, retain) NSNumber * messageCellHeight;

@end