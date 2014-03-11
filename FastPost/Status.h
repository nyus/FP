//
//  DisplayObject.h
//  FastPost
//
//  Created by Huang, Jason on 11/26/13.
//  Copyright (c) 2013 Huang, Jason. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Status;
@class PFObject;
@class PFFile;
@protocol StatusObjectDelegate <NSObject>
-(void)statusObjectTimeUpWithObject:(Status *)object;
-(void)statusObjectTimerCount:(int)count withStatusObject:(Status *)object;
@end

@interface Status : NSObject
//@property (nonatomic, strong) PFObject *pfObject;


@property (nonatomic, strong) NSString *message;
@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, strong) NSDate *updatedAt;
@property (nonatomic, strong) PFFile *picture;
@property (nonatomic, strong) NSString *posterUsername;
@property (nonatomic, strong) NSDate *expirationDate;
@property (nonatomic, assign) NSNumber *revivable;
@property (nonatomic, strong) NSNumber *expirationTimeInSec;
@property (nonatomic, strong) NSNumber *likeCount;
@property (nonatomic, strong) NSNumber *reviveCount;
@property (nonatomic, strong) NSString *countDownMessage;
@property (nonatomic, strong, readonly) NSTimer *timer;
@property (nonatomic, assign) id<StatusObjectDelegate>delegate;

//keep a reference to pfObject so that we can directly do stuff like setting expiration time on it and save it
@property (nonatomic, strong) PFObject *pfObject;
-(id)initWithPFObject:(PFObject *)pfObject;
-(void)startTimer;
@end
