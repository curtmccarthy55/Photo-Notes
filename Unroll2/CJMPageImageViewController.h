//
//  CJMPageImageViewController.h
//  Unroll
//
//  Created by Curt on 5/1/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CJMFullImageViewController.h"

@interface CJMPageImageViewController : UIPageViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate, CJMFullImageViewControllerDelegate>

@property (nonatomic) NSInteger initialIndex;
@property (nonatomic, strong) NSString *albumName;
@property (nonatomic, strong) UIPageViewController *pageViewController;
@property (nonatomic) NSInteger albumCount;

@end
