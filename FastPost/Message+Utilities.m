//
//  Message+Utilities.m
//  FastPost
//
//  Created by Huang, Jason on 2/26/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "Message+Utilities.h"
#import <Parse/Parse.h>
@implementation Message (Utilities)
-(void)updateSelfFromPFObject:(PFObject *)object{
    self.updatedAt = object.updatedAt;
    self.read = object[@"read"];
}
@end
