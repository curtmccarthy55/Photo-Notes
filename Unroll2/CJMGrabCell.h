//
//  GrabCell.h
//  Unroll
//
//  Created by Curt on 4/27/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import <UIKit/UIKit.h>

@import Photos;

@interface CJMGrabCell : UICollectionViewCell

@property (nonatomic, weak) IBOutlet UIView *cellSelectCover;
@property (nonatomic, strong) PHAsset *asset;
@property (nonatomic, strong) UIImage *thumbnailImage;
@property (nonatomic, weak) IBOutlet UIImageView *cellImage;

@end
