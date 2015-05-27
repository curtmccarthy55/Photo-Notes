//
//  CJMServices.h
//  Unroll
//
//  Created by Curt on 4/15/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CJMAlbumManager.h"

@class CJMImage;

typedef void (^CJMCompletionHandler)(NSArray *albums);

//a variable called CJMImageCompletionHandler that takes a UIImage argument and returns nothing.
typedef void (^CJMImageCompletionHandler)(UIImage *image);

@interface CJMServices : NSObject

+ (instancetype)sharedInstance;

- (void)fetchUserAlbums:(CJMCompletionHandler)handler;
- (void)fetchImage:(CJMImage *)image handler:(CJMImageCompletionHandler)handler;
- (void)fetchThumbnailForImage:(CJMImage *)image handler:(CJMImageCompletionHandler)handler;

- (BOOL)saveApplicationData;

@end