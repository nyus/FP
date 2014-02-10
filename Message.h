//
//  Message.h
//  FastPost
//
//  Created by Sihang Huang on 2/9/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Message : NSManagedObject

@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSString * objectid;
@property (nonatomic, retain) NSString * senderUsername;
@property (nonatomic, retain) NSString * receiverUsername;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSNumber * read;

@end
