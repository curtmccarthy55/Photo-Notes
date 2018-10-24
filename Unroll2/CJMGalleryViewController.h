//
//  CJMGalleryViewController.h
//  Unroll
//
//  Created by Curt on 4/13/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CJMPhotoGrabViewController.h"
#import "PHNPhotoGrabCompletionDelegate.h"

@class CJMPhotoAlbum;

@interface CJMGalleryViewController : UICollectionViewController <PHNPhotoGrabCompletionDelegate>

@property (nonatomic, weak) CJMPhotoAlbum *album;
@property (nonatomic, strong) UIColor *userColor;
@property (nonatomic, strong) NSNumber *userColorTag;

@end
