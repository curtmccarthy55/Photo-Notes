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

@property (nonatomic, strong) NSMutableOrderedSet<CJMImage *> *albumEditablePhotos;

@end

@implementation CJMPhotoAlbum

- (instancetype)initWithName:(NSString *)name andNote:(NSString *)note {
    self = [super init];
    
    if (self) {
        self.albumTitle = name;
        self.albumNote = note;
        self.albumEditablePhotos = [[NSMutableOrderedSet alloc] init];
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name {
    return [self initWithName:name andNote:@""];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.albumTitle forKey:@"Title"];
    [aCoder encodeObject:self.albumNote forKey:@"Note"];
    [aCoder encodeObject:self.albumEditablePhotos forKey:@"AlbumPhotos"];
    [aCoder encodeObject:self.albumPreviewImage forKey:@"PreviewImage"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.albumTitle = [coder decodeObjectForKey:@"Title"];
        self.albumNote = [coder decodeObjectForKey:@"Note"];
        self.albumEditablePhotos = [coder decodeObjectForKey:@"AlbumPhotos"];
        self.albumPreviewImage = [coder decodeObjectForKey:@"PreviewImage"];
    }
    return self;
}

- (NSString *)description {
    return  [NSString stringWithFormat:@"CJMPhotoAlbum with name:%@, memAddress:%p, and photoCount:%lu", self.albumTitle, self, (unsigned long)self.albumPhotos.count];
}

- (CJMPhotoAlbum *)copyWithZone:(NSZone *)zone { 
    CJMPhotoAlbum *albumCopy = [[CJMPhotoAlbum allocWithZone:zone] init];
    
    albumCopy.albumTitle = self.albumTitle ? [NSString stringWithString:self.albumTitle] : nil;
    albumCopy.albumNote = self.albumNote ? [NSString stringWithString:self.albumNote] : nil;
    albumCopy.albumPhotos = self.albumPhotos;
    albumCopy.albumPreviewImage = self.albumPreviewImage ? self.albumPreviewImage : nil;
    albumCopy.albumEditablePhotos = self.albumEditablePhotos ? self.albumEditablePhotos : nil;
    albumCopy.privateAlbum = self.privateAlbum;
    
    return albumCopy;
}

#pragma mark - Content management

- (NSArray *)albumPhotos {
    return [self.albumEditablePhotos array];
}

- (void)addCJMImage:(CJMImage *)image { //cjm favorites add
    [self.albumEditablePhotos addObject:image];
    if ([self.albumTitle isEqualToString:@"Favorites"]) {
        [self.delegate checkFavoriteCount];
    }
}

- (void)removeCJMImage:(CJMImage *)image {
    [self.albumEditablePhotos removeObject:image];
}

- (void)addMultipleCJMImages:(NSArray *)newImages {
    NSArray *sortedNewImages = [newImages sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"photoCreationDate" ascending:YES]]];
    
    [self.albumEditablePhotos addObjectsFromArray:sortedNewImages];
}

- (void)removeCJMImagesAtIndexes:(NSIndexSet *)indexSet {
    [self.albumEditablePhotos removeObjectsAtIndexes:indexSet];
}


@end
