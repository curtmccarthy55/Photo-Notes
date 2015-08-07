//
//  CJMPhotoAlbum.m
//  Unroll
//
//  Created by Curt on 4/12/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import "CJMPhotoAlbum.h"

@import Photos;

@interface CJMPhotoAlbum ()

@property (nonatomic, strong) NSMutableOrderedSet *albumEditablePhotos;

@end

@implementation CJMPhotoAlbum

- (instancetype)initWithName:(NSString *)name andNote:(NSString *)note
{
    self = [super init];
    
    if (self) {
        _albumTitle = name;
        _albumNote = note;
        _albumEditablePhotos = [[NSMutableOrderedSet alloc] init];
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name
{
    return [self initWithName:name andNote:@""];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.albumTitle forKey:@"Title"];
    [aCoder encodeObject:self.albumNote forKey:@"Note"];
    [aCoder encodeObject:self.albumEditablePhotos forKey:@"AlbumPhotos"];
    [aCoder encodeObject:self.albumPreviewImage forKey:@"PreviewImage"];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        _albumTitle = [coder decodeObjectForKey:@"Title"];
        _albumNote = [coder decodeObjectForKey:@"Note"];
        _albumEditablePhotos = [coder decodeObjectForKey:@"AlbumPhotos"];
        _albumPreviewImage = [coder decodeObjectForKey:@"PreviewImage"];
    }
    return self;
}

#pragma mark - Content management

- (NSArray *)albumPhotos
{
    return [_albumEditablePhotos array];
}

- (void)addCJMImage:(CJMImage *)image
{
    [_albumEditablePhotos addObject:image];
}

- (void)removeCJMImage:(CJMImage *)image
{
    [_albumEditablePhotos removeObject:image];
}

- (void)addMultipleCJMImages:(NSArray *)newImages
{
    NSArray *sortedNewImages = [newImages sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"photoCreationDate" ascending:YES]]];
    
    [_albumEditablePhotos addObjectsFromArray:sortedNewImages];
}

- (void)removeCJMImagesAtIndexes:(NSIndexSet *)indexSet
{
    [self.albumEditablePhotos removeObjectsAtIndexes:indexSet];
}


@end
