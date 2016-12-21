//
//  CJMAlbumStore.h
//  Unroll
//
//  Created by Curt on 4/12/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CJMPhotoAlbum.h"

@interface CJMAlbumManager : NSObject

@property (nonatomic, readonly) NSArray *allAlbums;
@property (nonatomic, readonly) CJMPhotoAlbum *favPhotosAlbum; //cjm favorites album

+ (instancetype)sharedInstance;

- (void)addAlbum:(CJMPhotoAlbum *)album;
- (void)removeAlbumAtIndex:(NSUInteger)index;
- (void)replaceAlbumAtIndex:(NSInteger)toIndex withAlbumFromIndex:(NSInteger)fromIndex;
- (BOOL)containsAlbumNamed:(NSString *)name;
- (CJMImage *)albumWithName:(NSString *)name returnImageAtIndex:(NSInteger)index;
- (void)albumWithName:(NSString *)albumName removeImageWithUUID:(NSString *)fileName;
- (void)albumWithName:(NSString *)name createPreviewFromCJMImage:(CJMImage *)image;
- (BOOL)save;

@end
