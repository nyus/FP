//
//  Message.h
//  FastPost
//
//  Created by Sihang on 8/16/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Message : NSManagedObject

@property (nonatomic, retain) NSNumber * countDown;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSDate * expirationDate;
@property (nonatomic, retain) NSNumber * expirationTimeInSec;
@property (nonatomic, retain) NSString * content;
@property (nonatomic, retain) NSString * objectid;
@property (nonatomic, retain) NSNumber * read;
@property (nonatomic, retain) NSString * receiverUsername;
@property (nonatomic, retain) NSString * senderUsername;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSNumber * numOfMissedMsgs;

@end
