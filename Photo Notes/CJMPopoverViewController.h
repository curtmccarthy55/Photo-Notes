//
//  CJMViewController.h
//  Photo Notes
//
//  Created by Curtis McCarthy on 12/6/16.
//  Copyright © 2016 Bluewraith. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CJMPopoverDelegate <NSObject>

- (void)editTappedForIndexPath:(NSIndexPath *)indexPath;

@end

@interface CJMPopoverViewController : UIViewController

@property (nonatomic, weak) id <CJMPopoverDelegate> delegate;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *note;
@property (nonatomic, strong) NSIndexPath *indexPath;

@end
