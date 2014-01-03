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
@protocol StatusObjectDelegate <NSObject>
-(void)statusObjectTimeUpWithObject:(Status *)object;
-(void)statusObjectTimerCount:(int)count withStatusObject:(Status *)object;
@end

@interface Status : NSObject
@property (nonatomic, strong) PFObject *pfObject;
@property (nonatomic, strong) NSString *message;
@property (nonatomic, strong) NSString *countDownMessage;
@property (nonatomic, strong, readonly) NSTimer *timer;
@property (nonatomic, assign) id<StatusObjectDelegate>delegate;
-(id)initWithPFObject:(PFObject *)pfObject;
-(void)startTimer;
@end
