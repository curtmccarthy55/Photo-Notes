//
//  CJMPhotoAlbum.h
//  Unroll
//
//  Created by Curt on 4/12/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CJMImage.h"

@class PHAsset;

@interface CJMPhotoAlbum : NSObject <NSCoding, NSCopying>

@property (nonatomic, strong) NSString *albumTitle;
@property (nonatomic, strong) NSString *albumNote;
@property (nonatomic) BOOL privateAlbum;
@property (nonatomic, strong) NSArray *albumPhotos;
@property (nonatomic, strong) CJMImage *albumPreviewImage;

- (instancetype)initWithName:(NSString *)name andNote:(NSString *)note;
- (instancetype)initWithName:(NSString *)name;
- (void)addCJMImage:(CJMImage *)image;
- (void)removeCJMImage:(CJMImage *)image;
- (void)addMultipleCJMImages:(NSArray *)newImages;
- (void)removeCJMImagesAtIndexes:(NSIndexSet *)indexSet;

@end
