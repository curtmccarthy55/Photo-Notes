//
//  CJMPhotoCell.h
//  Unroll
//
//  Created by Curt on 4/19/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CJMImage.h"



@interface CJMPhotoCell : UICollectionViewCell


@property (nonatomic, readonly) CJMImage *image;

- (void)updateWithImage:(CJMImage *)image;

@end
