//
//  CJMPhotoGrabViewController.h
//  Unroll
//
//  Created by Curt on 4/19/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import <UIKit/UIKit.h>
@import Photos;

@class CJMPhotoGrabViewController;
@protocol PHNPhotoGrabCompletionDelegate;

@interface CJMPhotoGrabViewController : UIViewController

@property (nonatomic, weak) id <PHNPhotoGrabCompletionDelegate> delegate;
@property (nonatomic, strong) UIColor *userColor;
@property (nonatomic, strong) NSNumber *userColorTag;
@property (nonatomic) BOOL singleSelection;
@property (nonatomic, strong) PHFetchResult *fetchResult;

@end
