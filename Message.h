//
//  Message.h
//  FastPost
//
//  Created by Sihang Huang on 2/23/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Message : NSManagedObject

@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSString * objectid;
@property (nonatomic, retain) NSNumber * read;
@property (nonatomic, retain) NSString * receiverUsername;
@property (nonatomic, retain) NSString * senderUsername;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSNumber * expirationTimeInSec;
@property (nonatomic, retain) NSDate * expirationDate;

@end
