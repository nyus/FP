//
//  Status.h
//  FastPost
//
//  Created by Sihang Huang on 3/11/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface StatusObject : NSManagedObject

@property (nonatomic, retain) NSString * avatar;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSString * picture;
@property (nonatomic, retain) NSString * username;

@end
