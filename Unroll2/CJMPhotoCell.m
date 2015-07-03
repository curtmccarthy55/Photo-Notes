//
//  CJMPhotoCell.m
//  Unroll
//
//  Created by Curt on 4/19/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import "CJMPhotoCell.h"
#import "CJMServices.h"


@interface CJMPhotoCell ()

@property (weak, nonatomic) IBOutlet UIImageView *cellImage;
@property (nonatomic, weak) UIImage *thumbnailImage;
@property (nonatomic) CJMImage *image;

@end

@implementation CJMPhotoCell

#pragma ALERT Check to see if this method is even necessary.  I don't believe it's called anywhere.
- (void)setThumbnailImage:(UIImage *)thumbnailImage
{
    _thumbnailImage = thumbnailImage;
    self.cellImage.image = thumbnailImage;
}

- (void)updateWithImage:(CJMImage *)cjmImage
{
    self.image = cjmImage;
    [[CJMServices sharedInstance] fetchThumbnailForImage:cjmImage handler:^(UIImage *thumbnail) {
        self.cellImage.image = thumbnail;
        NSLog(@"image address is %@", thumbnail);
    }];
    //self.cellSelectCover.hidden = self.image.selectCoverHidden;
}



@end
