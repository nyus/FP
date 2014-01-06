//
//  ExpirationTimePickerViewController.m
//  FastPost
//
//  Created by Huang, Jason on 12/11/13.
//  Copyright (c) 2013 Huang, Jason. All rights reserved.
//

#import "ExpirationTimePickerViewController.h"

@interface ExpirationTimePickerViewController ()<UIPickerViewDataSource, UIPickerViewDelegate>{
    NSArray *pickerMinuteDataSource;
    PickerType _type;
}
@end

@implementation ExpirationTimePickerViewController

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil type:(PickerType)type{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _type = type;
        // Custom initialization
        self.pickerView.dataSource = self;
        self.pickerView.delegate = self;
        if (type == PickerTypeFilter) {
            [self configureFilterPickerViewDataSource];
        }else if(type == PickerTypeRevive){
            [self configureRevivePickerViewDataSource];
        }
        
        [self.pickerView reloadAllComponents];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.pickerView.dataSource = self;
        self.pickerView.delegate = self;
        [self configureRevivePickerViewDataSource];
        [self.pickerView reloadAllComponents];
    }
    return self;
}

-(void)setType:(PickerType)type{
    _type = type;
    [self.pickerView reloadAllComponents];
}

-(void)configureRevivePickerViewDataSource{
    pickerMinuteDataSource = [NSArray arrayWithObjects:@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9",@"10",@"15",@"20",@"30", nil];
}

-(void)configureFilterPickerViewDataSource{
    pickerMinuteDataSource = [NSArray arrayWithObjects:
                              @"Less than 5 mins",
                              @"Less than 10 mins",
                              @"Less than 15 mins",
                              @"Less than 20 mins",
                              @"Less than 25 mins",
                              @"Less than 30 mins",
                              nil];
}

#pragma mark - uipickerview delegate

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    if (_type == PickerTypeRevive) {
        // 2 min 5 secs
        return 4;
    }else{
        return 1;
    }
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    
    if (_type == PickerTypeRevive) {
        if (component == 0) {
            //min  0 -29
            return 30;
        }else if (component == 1){
            return 1;
        }else if(component == 2){
            //sec 0 - 59
            return 60;
        }else{
            return 1;
        }
    }else if (_type == PickerTypeFilter){
        return pickerMinuteDataSource.count;
    }else{
        return 0;
    }
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    if (_type == PickerTypeRevive) {
        if (component == 0 || component == 2) {
            return [NSString stringWithFormat:@"%d",row];
        }else if(component == 1){
            return @"mins";
        }else{
            return @"sec";
        }
    }else if(_type == PickerTypeFilter){
        return pickerMinuteDataSource[row];
    }else{
        return nil;
    }
}

-(CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component{
    if (_type == PickerTypeRevive) {
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
    }else if(_type == PickerTypeFilter){
        return self.view.frame.size.width;
    }else{
        return 0;
    }
}

-(CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component{
    if (_type == PickerTypeRevive) {
        return 20;
    }else if (_type == PickerTypeFilter){
        return 40;
    }else{
        return 0;
    }
}


- (IBAction)doneButtonTapped:(id)sender {
    if (_type==PickerTypeRevive) {
        [self.delegate revivePickerViewExpirationTimeSetToMins:[self.pickerView selectedRowInComponent:0] andSecs:[self.pickerView selectedRowInComponent:2] andPickerView:self.pickerView];
    }else if (_type == PickerTypeFilter){
        [self.delegate filterPickerViewExpirationTimeSetToLessThanMins:([self.pickerView selectedRowInComponent:0]+1)*5 andPickerView:self.pickerView];
    }
    
    [UIView animateWithDuration:.3 animations:^{
        self.view.alpha = 0.0f;
        self.blurToolBar.alpha = 0.0f;
    }];
}

- (IBAction)cancelButtonTapped:(id)sender {
    [UIView animateWithDuration:.3 animations:^{
        self.view.alpha = 0.0f;
        self.blurToolBar.alpha = 0.0f;
    }];
}
@end
