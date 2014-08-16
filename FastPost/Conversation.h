//
//  Conversation.h
//  FastPost
//
//  Created by Sihang on 8/16/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Conversation : NSManagedObject

@property (nonatomic, retain) id participants;
@property (nonatomic, retain) NSString * objectid;
@property (nonatomic, retain) NSDate * lastUpdateDate;
@property (nonatomic, retain) NSString * lastMessageContent;

@end
