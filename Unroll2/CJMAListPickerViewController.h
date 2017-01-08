//
//  CJMAListPickerViewController.h
//  Photo Notes
//
//  Created by Curt on 6/13/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CJMPhotoAlbum;
@class CJMAListPickerViewController;

@protocol CJMAListPickerDelegate <NSObject>

- (void)aListPickerViewControllerDidCancel:(CJMAListPickerViewController *)controller;
- (void)aListPickerViewController:(CJMAListPickerViewController *)controller didFinishPickingAlbum:(CJMPhotoAlbum *)album;

@end

@interface CJMAListPickerViewController : UITableViewController

@property (nonatomic, weak) id <CJMAListPickerDelegate> delegate;
@property (nonatomic, strong) NSString *currentAlbumName;
@property (nonatomic, strong) UIColor *userColor;

@end
