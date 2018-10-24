//
//  PHNImportAlbumsVC.h
//  Unroll2
//
//  Created by Curtis McCarthy on 10/16/18.
//  Copyright © 2018 Bluewraith. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PHNPhotoGrabCompletionDelegate;

@interface PHNImportAlbumsVC : UITableViewController

@property (nonatomic, weak) id <PHNPhotoGrabCompletionDelegate> delegate;
@property (nonatomic, strong) UIColor *userColor;
@property (nonatomic, strong) NSNumber *userColorTag;

@end
