//
//  CJMAListViewController.h
//  Unroll
//
//  Created by Curt on 4/12/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CJMADetailViewController.h"
#import "CJMFullImageViewController.h"

@interface CJMAListViewController : UITableViewController <CJMADetailViewControllerDelegate, CJMFullImageViewControllerDelegate>

- (void)takePhoto;

@end
