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

+ (instancetype)sharedInstance;
- (CJMImage *)albumWithName:(NSString *)name returnImageAtIndex:(NSInteger)index;
- (void)addAlbum:(CJMPhotoAlbum *)album;
- (void)removeAlbum:(CJMPhotoAlbum *)album;
- (void)replaceAlbumAtIndex:(NSInteger)index withAlbum:(CJMPhotoAlbum *)album;
- (BOOL)containsAlbumNamed:(NSString *)name;
- (BOOL)save;

- (void)albumWithName:(NSString *)name createPreviewFromCJMImage:(CJMImage *)image;

@end
