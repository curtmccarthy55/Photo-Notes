//
//  PHNImportAlbumsVC.h
//  Unroll2
//
//  Created by Curtis McCarthy on 10/16/18.
//  Copyright © 2018 Bluewraith. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PHNPhotoGrabCompletionDelegate.h"

@interface PHNImportAlbumsVC : UITableViewController

@property (nonatomic, weak) id <PHNPhotoGrabCompletionDelegate> delegate;

@end
