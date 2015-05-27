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

@interface CJMPhotoAlbum : NSObject <NSCoding>

@property (nonatomic, strong) NSString *albumTitle;
@property (nonatomic, strong) NSString *albumNote;
@property (nonatomic) BOOL privateAlbum;
@property (nonatomic, strong) NSArray *albumPhotos;  //This might need to go into the CJMImageStore.
@property (nonatomic, strong) CJMImage *albumPreviewImage;


- (instancetype)initWithName:(NSString *)name andNote:(NSString *)note;
- (instancetype)initWithName:(NSString *)name;
//- (void)addAsset:(PHAsset *)asset;
//- (void)addAssetsFromArray:(NSArray *)array;
- (void)addCJMImage:(CJMImage *)image;

@end
