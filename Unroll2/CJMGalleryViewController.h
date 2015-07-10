//
//  CJMGalleryViewController.h
//  Unroll
//
//  Created by Curt on 4/13/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CJMPhotoGrabViewController.h"

@class CJMPhotoAlbum;

@interface CJMGalleryViewController : UICollectionViewController <CJMPhotoGrabViewControllerDelegate>

@property (nonatomic, weak) CJMPhotoAlbum *album;  //changed from strong to weak


@end
