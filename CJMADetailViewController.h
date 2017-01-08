//
//  CJMADetailViewController.h
//  Unroll
//
//  Created by Curt on 4/13/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CJMADetailViewController;
@class CJMPhotoAlbum;

@protocol CJMADetailViewControllerDelegate <NSObject>

- (void)albumDetailViewControllerDidCancel:(CJMADetailViewController *)controller;
- (void)albumDetailViewController:(CJMADetailViewController *)controller didFinishAddingAlbum:(CJMPhotoAlbum *)album;
- (void)albumDetailViewController:(CJMADetailViewController *)controller didFinishEditingAlbum:(CJMPhotoAlbum *)album;

@end

@interface CJMADetailViewController : UITableViewController

@property (nonatomic, strong) CJMPhotoAlbum *albumToEdit;
@property (nonatomic, weak) id <CJMADetailViewControllerDelegate> delegate;
@property (nonatomic, strong) UIColor *userColor;
@property (nonatomic, strong) NSNumber *userColorTag;

@end
