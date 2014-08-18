//
//  Message+Utilities.m
//  FastPost
//
//  Created by Huang, Sihang on 2/26/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "Message+Utilities.h"
#import <Parse/Parse.h>
@implementation Message (Utilities)
-(void)updateSelfFromPFObject:(PFObject *)object{
    self.updatedat = object.updatedAt;
    self.read = object[@"read"];
}
@end
