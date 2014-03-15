//
//  Message+Utilities.h
//  FastPost
//
//  Created by Huang, Sihang on 2/26/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "Message.h"
@class PFObject;
@interface Message (Utilities)
-(void)updateSelfFromPFObject:(PFObject *)object;
@end
