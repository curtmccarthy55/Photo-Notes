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

- (void)updateWithImage:(CJMImage *)cjmImage
{
    self.image = cjmImage;
    [[CJMServices sharedInstance] fetchThumbnailForImage:cjmImage handler:^(UIImage *thumbnail) {
        //if thumbnail not properly captured during import, create one
        if (thumbnail.size.width == 0) {
            cjmImage.thumbnailNeedsRedraw = YES;
            [[CJMServices sharedInstance] removeImageFromCache:cjmImage];
        } else {
            self.cellImage.image = thumbnail;
        }
    }];

}



@end
