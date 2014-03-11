//
//  ComposeNewStatusViewController.m
//  FastPost
//
//  Created by Huang, Jason on 12/4/13.
//  Copyright (c) 2013 Huang, Jason. All rights reserved.
//

#import "ComposeNewStatusViewController.h"
#import "ComposeStatusPhotoCollectionViewCell.h"
#import <Parse/Parse.h>
#define CELL_IMAGEVIEW_SIZE_HEIGHT 204.0f
#define CELL_IMAGEVIEW_SIZE_WIDTH 280.0f
@interface ComposeNewStatusViewController ()<UIPickerViewDelegate, UIPickerViewDataSource,UITextViewDelegate,UIImagePickerControllerDelegate, UINavigationControllerDelegate,UIActionSheetDelegate,UICollectionViewDataSource,UICollectionViewDelegate>{
    UIImagePickerController *imagePicker;
    UILabel *placeHolderLabel;
    NSMutableArray *collectionViewDataSource;
    NSArray *pickerDataSource;
}

@property (strong, nonatomic) UIActionSheet *photosActionSheet;
@end

@implementation ComposeNewStatusViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self configurePickerViewDataSource];
    [self configurePickerView];
    [self configureTextView];
    [self configureExpirationTimeLabel];
    
    if (!IS_4_INCH_SCREEN) {
        int delta = self.textViewHeightConstraint.constant - 140;
        self.textViewHeightConstraint.constant = 140;
        self.collectionViewTopSpacingConstraint.constant = self.collectionViewTopSpacingConstraint.constant - delta;
    }
    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.textView layoutIfNeeded];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)configureExpirationTimeLabel{
   // self.experiationTimeLabel.text = [NSString stringWithFormat:@"%d:%02d",[self.pickerView selectedRowInComponent:0],[self.pickerView selectedRowInComponent:2]];
    self.experiationTimeLabel.text = [NSString stringWithFormat:@"%d:00",[pickerDataSource[[self.pickerView selectedRowInComponent:0]] intValue]];
}

-(void)configurePickerView{

    //choose 0 min 10 secs by default
    [self.pickerView selectRow:0 inComponent:0 animated:NO];
//    [self.pickerView selectRow:10 inComponent:2 animated:NO];
}

-(void)configurePickerViewDataSource{
    pickerDataSource = [NSArray arrayWithObjects:@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9",@"10",@"15",@"20",@"30", nil];
}

-(void)configureTextView{
    [self.textView becomeFirstResponder];
    if (self.textView.hasText) {
        [self hidePlaceHolderText];
    }else{
        [self showPlaceHolderText];
    }
}

-(void)showPlaceHolderText{
    if (!placeHolderLabel) {
        placeHolderLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 12, 200, 20)];
        placeHolderLabel.backgroundColor = [UIColor clearColor];
        placeHolderLabel.font = [UIFont fontWithName:@"AvenirNextCondensed-Regular" size:18];
        placeHolderLabel.textColor = [UIColor grayColor];
        placeHolderLabel.text = @"What's on your mind?";
        [self.textView addSubview:placeHolderLabel];
    }
    placeHolderLabel.hidden = NO;
}

-(void)hidePlaceHolderText{
    placeHolderLabel.hidden = YES;
}

-(void)showTimePicker{
    [UIView animateWithDuration:.3 animations:^{
        self.pickerViewVerticalSpaceConstraint.constant = 0;
        [self.pickerView layoutIfNeeded];
    }];
}

-(void)hideTimePicker{
    [UIView animateWithDuration:.3 animations:^{
        self.pickerViewVerticalSpaceConstraint.constant = -self.pickerView.frame.size.height;
        [self.pickerView layoutIfNeeded];
    }];
}

-(void)changeTextViewHeightToFitPhoto{
    
    if (!IS_4_INCH_SCREEN) {
        self.textViewHeightConstraint.constant = 46;
    }else{
        self.textViewHeightConstraint.constant = 111;
    }
    
    [self scrollTextViewToShowCursor];
}

-(void)showCollectionViewAndLineSeparator{
    self.textPhotoSeparatorView.alpha = 1.0f;
    self.collectionView.alpha = 1.0f;
}

- (void)scrollTextViewToShowCursor {
    [self.textView scrollRectToVisible:CGRectMake(0, 0, self.textView.frame.size.width, self.textView.contentSize.height) animated:YES];
}

#pragma mark - uipickerview delegate

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    // 2 min 5 secs
//    return 4;
    return 2;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
//    if (component == 0) {
//        //min  0 -9
//        return 10;
//    }else if (component == 1){
//        return 1;
//    }else if(component == 2){
//        //sec 0 - 59
//        return 60;
//    }else{
//        return 1;
//    }
    if (component == 0) {
        //min  1 -10 15 20 30
        return pickerDataSource.count;
    }else{
        //mins word
        return 1;
    }
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
//    if (component == 0 || component == 2) {
//        return [NSString stringWithFormat:@"%d",row];
//    }else if(component == 1){
//        return @"mins";
//    }else{
//        return @"sec";
//    }
    if (component == 0) {
        return pickerDataSource[row];
    }else{
        return @"mins";
    }
}

-(CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component{
    switch (component) {
        case 0:
            return 60;
            break;
        case 1:
            return 60;
            break;
        case 2:
            return 60;
            break;
        default:
            return 60;
            break;
    }
}

-(CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component{
    return 20;
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
//    self.experiationTimeLabel.text = [NSString stringWithFormat:@"%d:%02d",[pickerView selectedRowInComponent:0],[pickerView selectedRowInComponent:2]];
    self.experiationTimeLabel.text = [NSString stringWithFormat:@"%d:00",[pickerDataSource[[pickerView selectedRowInComponent:0]] intValue]];
}

#pragma mark - UITextViewDelegate

-(void)textViewDidBeginEditing:(UITextView *)textView{
    [self hideTimePicker];
    
}

-(BOOL)textViewShouldBeginEditing:(UITextView *)textView{
    [self performSelector:@selector(scrollTextViewToShowCursor) withObject:nil afterDelay:0.1f];
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if (textView.text.length == 1 && [text isEqualToString:@""]) {
        [self showPlaceHolderText];
    }else{
        [self hidePlaceHolderText];
    }
    
    [self performSelector:@selector(scrollTextViewToShowCursor) withObject:NSStringFromRange(range) afterDelay:0.1f];
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange{
    return YES;
}

#pragma mark - IBAction

- (IBAction)attachPhotoButtonTapped:(id)sender {
    
    [self.textView resignFirstResponder];
    [self hideTimePicker];
    self.photosActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take Photo",@"Add From Gallery", nil];
    [self.photosActionSheet showInView:self.view];
}

- (IBAction)setTimeButtonTapped:(id)sender {
    
    [self.textView resignFirstResponder];
    [self showTimePicker];

}

- (IBAction)sendButtonTapped:(id)sender {

    if ([[self.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]) {
        return;
    }
    
    //send to parse
    [self dismissViewControllerAnimated:YES completion:^{
        
        if (!collectionViewDataSource && !collectionViewDataSource[0]) {
            PFObject *object = [PFObject objectWithClassName:@"Status"];
            object[@"message"] = self.textView.text;
            //        object[@"expirationTimeInSec"] = [NSNumber numberWithInt:[self.pickerView selectedRowInComponent:0]*60 + [self.pickerView selectedRowInComponent:2]];
            //        object[@"expirationDate"] = [[NSDate date] dateByAddingTimeInterval:[self.pickerView selectedRowInComponent:0]*60 + [self.pickerView selectedRowInComponent:2]];
            
            object[@"expirationTimeInSec"] = [NSNumber numberWithInt:[pickerDataSource[[self.pickerView selectedRowInComponent:0]] intValue] *60];
            object[@"expirationDate"] = [[NSDate date] dateByAddingTimeInterval:[pickerDataSource[[self.pickerView selectedRowInComponent:0]] intValue]*60];
            object[@"posterUsername"] = [[PFUser currentUser] username];
            object[@"revivable"] = [NSNumber numberWithBool:self.revivableSwitch.on];
            [object saveInBackground];
        }else{
            UIImage *chosenImage = collectionViewDataSource[0];
            //
            float scale = 0.0f;
            if (chosenImage.size.width > chosenImage.size.height) {
                scale = CELL_IMAGEVIEW_SIZE_WIDTH/chosenImage.size.width;
            }else{
                scale = CELL_IMAGEVIEW_SIZE_HEIGHT/chosenImage.size.height;
            }
            //reason for scale*2. UIImageJPEGRepresentation's compressionQuality seems to be 2 times the value of scale
            //for example, if compressionQuality is 0.8, then the size would be appro 0.4 time of the original size
            NSData *data = UIImageJPEGRepresentation(collectionViewDataSource[0],scale*2);
            PFFile *image = [PFFile fileWithData:data];
            [image saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded && !error) {
                    PFObject *object = [PFObject objectWithClassName:@"Status"];
                    object[@"message"] = self.textView.text;
                    object[@"picture"] = image;
                    //        object[@"expirationTimeInSec"] = [NSNumber numberWithInt:[self.pickerView selectedRowInComponent:0]*60 + [self.pickerView selectedRowInComponent:2]];
                    //        object[@"expirationDate"] = [[NSDate date] dateByAddingTimeInterval:[self.pickerView selectedRowInComponent:0]*60 + [self.pickerView selectedRowInComponent:2]];
                    
                    object[@"expirationTimeInSec"] = [NSNumber numberWithInt:[pickerDataSource[[self.pickerView selectedRowInComponent:0]] intValue] *60];
                    object[@"expirationDate"] = [[NSDate date] dateByAddingTimeInterval:[pickerDataSource[[self.pickerView selectedRowInComponent:0]] intValue]*60];
                    object[@"posterUsername"] = [[PFUser currentUser] username];
                    object[@"revivable"] = [NSNumber numberWithBool:self.revivableSwitch.on];
                    [object saveInBackground];
                }
            }];
        }
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSNumber *numberPosts = [defaults objectForKey:@"numberofposts"];
        //first time use
        if (!numberPosts) {
            [defaults setObject:[NSNumber numberWithInt:1] forKey:@"numberofposts"];
        }else{
            [defaults setObject:[NSNumber numberWithInt:numberPosts.intValue+1] forKey:@"numberofposts"];
        }
        [defaults synchronize];
    }];
}

- (IBAction)cancelButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)revivableSwitchChanged:(id)sender {
}

#pragma mark - UIActionSheetDelegate

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    // Dismiss the actionSheet before launching the camera, so that it doesn't jump into portrait for a split second
    [self.photosActionSheet dismissWithClickedButtonIndex:999 animated:YES];
    
    if(buttonIndex == 0){
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            // this is for a bug when you first add from gallery, then take a photo, the picker view controller shifts down
            //            if (imagePicker == nil) {
            imagePicker = [[UIImagePickerController alloc] init];
            //            }
            imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
            imagePicker.allowsEditing = NO;
            imagePicker.cameraCaptureMode = (UIImagePickerControllerCameraCaptureModePhoto);
            imagePicker.delegate = self;
            [self presentViewController:imagePicker animated:YES completion:nil];
        }
    }else if(buttonIndex == 1){

        imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.delegate = self;
        imagePicker.allowsEditing = NO;
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:imagePicker animated:YES completion:nil];
    }else{
        [self.textView becomeFirstResponder];
    }
}

#pragma mark - image picker delegates

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    if (!image) {
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:[[info objectForKey:UIImagePickerControllerReferenceURL] absoluteString]]];
        image = [UIImage imageWithData:data];
    }
    // If photot did not come from photo album, add photo to our custom album and the regular camera roll
    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
//        [self saveImageToAlbum:image];
    } else {
        //If photo came from regular album, add to custom album only
//        [self saveImageFromAssetURL:[info objectForKey:@"UIImagePickerControllerReferenceURL"]];
    }
    
    if (!collectionViewDataSource) {
        collectionViewDataSource = [NSMutableArray array];
    }
    [collectionViewDataSource addObject:image];
    
    [self.collectionView reloadData];
    
    [picker dismissViewControllerAnimated:YES completion:^{
        [UIView animateWithDuration:.2 animations:^{
            [self changeTextViewHeightToFitPhoto];
            [self showCollectionViewAndLineSeparator];
        }];
        
        [self.textView becomeFirstResponder];
    }];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [self dismissViewControllerAnimated:YES completion:^{
        [self.textView becomeFirstResponder];
    }];
}

#pragma mark - UICollectionViewDelegate

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return collectionViewDataSource.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    ComposeStatusPhotoCollectionViewCell *cell = (ComposeStatusPhotoCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.imageView.image = [collectionViewDataSource objectAtIndex:indexPath.row];
    return cell;
}
@end
