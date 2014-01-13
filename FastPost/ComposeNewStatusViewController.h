//
//  ComposeNewStatusViewController.h
//  FastPost
//
//  Created by Huang, Jason on 12/4/13.
//  Copyright (c) 2013 Huang, Jason. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ComposeNewStatusViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *pickerViewVerticalSpaceConstraint;
@property (weak, nonatomic) IBOutlet UILabel *experiationTimeLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIView *textPhotoSeparatorView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewHeightConstraint;
@property (weak, nonatomic) IBOutlet UISwitch *revivableSwitch;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *collectionViewTopSpacingConstraint;
- (IBAction)attachPhotoButtonTapped:(id)sender;
- (IBAction)setTimeButtonTapped:(id)sender;
- (IBAction)sendButtonTapped:(id)sender;
- (IBAction)cancelButtonTapped:(id)sender;
- (IBAction)revivableSwitchChanged:(id)sender;

@end
