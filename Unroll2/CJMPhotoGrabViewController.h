//
//  CJMPhotoGrabViewController.h
//  Unroll
//
//  Created by Curt on 4/19/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "CJMImage.h"
@import Photos;

@class CJMPhotoGrabViewController;

@protocol CJMPhotoGrabViewControllerDelegate <NSObject>

- (void)photoGrabViewControllerDidCancel:(CJMPhotoGrabViewController *)controller;

- (void)photoGrabViewController:(CJMPhotoGrabViewController *)controller didFinishSelectingPhotos:(NSArray *)photos;

@end

@interface CJMPhotoGrabViewController : UIViewController

@property (nonatomic, weak) id <CJMPhotoGrabViewControllerDelegate> delegate;

@end
