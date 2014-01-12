//
//  StatusTableCell.m
//  FastPost
//
//  Created by Huang, Jason on 11/25/13.
//  Copyright (c) 2013 Huang, Jason. All rights reserved.
//

#import "StatusTableViewCell.h"
#import "UIImage+ImageEffects.h"
@interface StatusTableViewCell(){
    int timeCount;
    BOOL timerStarted;
}
@end

@implementation StatusTableViewCell


-(id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
    }
    
    return self;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

//-(void)blurCell{
////    
////    if (!self.blurImageView.image) {
////        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
////        dispatch_async(queue, ^{
////            UIGraphicsBeginImageContext(self.bounds.size);
////            [self.layer renderInContext:UIGraphicsGetCurrentContext()];
////            UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
////            UIGraphicsEndImageContext();
////            
////            CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
////            [blurFilter setDefaults];
////            
////            CIImage *imageToBlur = [CIImage imageWithCGImage:image.CGImage];
////            [blurFilter setValue:imageToBlur forKey:kCIInputImageKey];
////            [blurFilter setValue:@3.0 forKey:@"inputRadius"];
////            
////            CIImage *outputImage = blurFilter.outputImage;
////            
////            dispatch_queue_t main = dispatch_get_main_queue();
////            dispatch_sync(main, ^{
////                self.blurImageView.image = [UIImage imageWithCIImage:outputImage];
////            });
////        });
////        
////        
////    }
////    
////    self.blurImageView.hidden = NO;
//
//    CGRect newFrame = self.containerView.frame;
//    newFrame.origin = CGPointMake(-newFrame.size.width/2, newFrame.origin.y);
//    [UIView animateWithDuration:.3 animations:^{
//        self.containerView.frame = newFrame;
//    }];
//}

//-(void)setPlaceHolderImage{
//    UIImage *image = [UIImage imageNamed:@"placeholder_picture"];
//    self.pictureImageView.image = image;
//}

//-(void)unblurCell{
//    CGRect newFrame = self.containerView.frame;
//    newFrame.origin = CGPointMake(0, newFrame.origin.y);
//    self.containerView.frame = newFrame;
//}

-(void)layoutSubviews{
    [self resizeCellToFitStatusContent];
}

-(void)resizeCellToFitStatusContent{

    CGSize maxSize = CGSizeMake(280, MAXFLOAT);
    
    CGRect rect = [self.statusCellMessageLabel.text boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont fontWithName:@"AvenirNextCondensed-Regular" size:17]} context:nil];
    
    int numberOfLines = ceilf(rect.size.width/280.0f);
    int heightOfLabel = (int)ceilf(numberOfLines *rect.size.height);
    
    self.statusCellMessageLabel.frame = CGRectMake(self.statusCellMessageLabel.frame.origin.x,
                                  self.statusCellMessageLabel.frame.origin.y,
                                  self.statusCellMessageLabel.frame.size.width,
                                  heightOfLabel);
    
    self.statusCellPhotoImageView.frame = CGRectMake(self.statusCellPhotoImageView.frame.origin.x,
                                             CGRectGetMaxY(self.statusCellMessageLabel.frame) + 10,
                                             self.statusCellPhotoImageView.frame.size.width,
                                             self.statusCellPhotoImageView.frame.size.height);
}

- (IBAction)reviveStatusButtonTapped:(id)sender {
    [self.delegate reviveStatusButtonTappedOnCell:self];
}

@end
