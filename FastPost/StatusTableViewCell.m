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
        [self.statusCellUsernameLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(usernameLabelTapped:)]];
    }
    
    return self;
}

-(void)layoutSubviews{
    [self resizeCellToFitStatusContent];
}

-(void)resizeCellToFitStatusContent{

    [self.statusCellMessageLabel sizeToFit];
    
    self.statusCellPhotoImageView.frame = CGRectMake(self.statusCellPhotoImageView.frame.origin.x,
                                             CGRectGetMaxY(self.statusCellMessageLabel.frame) + 10,
                                             self.statusCellPhotoImageView.frame.size.width,
                                             self.statusCellPhotoImageView.frame.size.height);
}

- (IBAction)reviveStatusButtonTapped:(id)sender {
    [self.delegate reviveStatusButtonTappedOnCell:self];
}
- (IBAction)userNameTapped:(id)sender {
    [self.delegate usernameLabelTappedOnCell:self];
}

-(void)usernameLabelTapped:(UITapGestureRecognizer *)tap{
    [self.delegate usernameLabelTappedOnCell:self];
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
@end
