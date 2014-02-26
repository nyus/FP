//
//  Message+Utilities.h
//  FastPost
//
//  Created by Huang, Jason on 2/26/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "Message.h"
@class PFObject;
@interface Message (Utilities)
-(void)updateSelfFromPFObject:(PFObject *)object;
@end
