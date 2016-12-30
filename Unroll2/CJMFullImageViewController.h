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

- (void)toggleFullImageShow:(BOOL)yesOrNo forViewController:(CJMFullImageViewController *)viewController;
- (void)viewController:(CJMFullImageViewController *)currentVC deletedImageAtIndex:(NSInteger)imageIndex;
- (void)photoIsFavorited:(BOOL)isFavorited; //cjm favorites ImageVC -> PageVC

@end

@interface CJMFullImageViewController : UIViewController <UIScrollViewDelegate>

@property (nonatomic, strong) NSString *albumName;
@property (nonatomic) NSInteger index;
@property (nonatomic, weak) id <CJMFullImageViewControllerDelegate> delegate;
@property (nonatomic) BOOL viewsVisible;
@property (nonatomic) BOOL imageIsFavorite;//cjm favorites ImageVC set up

- (void)showPopUpMenu;
- (void)confirmImageDelete;
- (void)actionFavorite:(BOOL)userFavorited; //cjm favorites PageVC -> ImageVC

@end
