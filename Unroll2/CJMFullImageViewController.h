//
//  CJMFullImageViewController.h
//  Unroll
//
//  Created by Curt on 4/24/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CJMPhotoAlbum;
@class CJMFullImageViewController;

@protocol CJMFullImageViewControllerDelegate <NSObject>

@optional
- (void)updateBarsHidden:(BOOL)setting;
- (void)makeHomeIndicatorVisible:(BOOL)visible;
- (void)viewController:(CJMFullImageViewController *)currentVC deletedImageAtIndex:(NSInteger)imageIndex;
- (void)photoIsFavorited:(BOOL)isFavorited;     //cjm favorites ImageVC -> PageVC

@end

@interface CJMFullImageViewController : UIViewController <UIScrollViewDelegate>

@property (nonatomic, strong) NSString *albumName;
@property (nonatomic) NSInteger index;
@property (nonatomic, weak) id <CJMFullImageViewControllerDelegate> delegate;
@property (nonatomic) BOOL barsVisible;         //top/bottom bars are visible
@property (nonatomic) BOOL imageIsFavorite;     //cjm favorites ImageVC set up
@property (nonatomic) BOOL isQuickNote;
@property (nonatomic) CGFloat noteOpacity;
@property (nonatomic, strong) UIColor *userColor;
@property (nonatomic, strong) NSNumber *userColorTag;

- (void)showPopUpMenu;
- (void)confirmImageDelete;
- (void)actionFavorite:(BOOL)userFavorited;     //cjm favorites PageVC -> ImageVC

@end
