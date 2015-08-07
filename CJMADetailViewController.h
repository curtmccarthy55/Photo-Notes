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
@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UITextView *noteField;
@property (nonatomic, weak) id <CJMADetailViewControllerDelegate> delegate;

@end
