//
//  Conversation.h
//  FastPost
//
//  Created by Sihang on 8/25/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Conversation : NSManagedObject

@property (nonatomic, retain) NSString * lastMessageContent;
@property (nonatomic, retain) NSDate * lastFetchServerDate;
@property (nonatomic, retain) NSString * objectid;
@property (nonatomic, retain) id participants;
@property (nonatomic, retain) NSDate * lastUpdateDate;

@end
