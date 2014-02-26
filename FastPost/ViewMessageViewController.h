//
//  ViewMessageViewController.h
//  FastPost
//
//  Created by Huang, Jason on 2/26/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewMessageViewController : UIViewController
@property (nonatomic, strong) NSString *message;
@property (weak, nonatomic) IBOutlet UITextView *messageTextView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *messageTextViewHeightContraint;
@end
