//
//  CJMImage.m
//  Unroll
//
//  Created by Curt on 4/13/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import "CJMImage.h"

@interface CJMImage ()

@end

@implementation CJMImage

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    if(self) {
        self.name = [aDecoder decodeObjectForKey:@"Name"];
        self.local = [aDecoder decodeBoolForKey:@"Local"];
        self.photoID = [aDecoder decodeObjectForKey:@"photoID"];
        self.photoTitle = [aDecoder decodeObjectForKey:@"Title"];
        self.photoNote = [aDecoder decodeObjectForKey:@"Note"];
        self.photoCreationDate = [aDecoder decodeObjectForKey:@"CreationDate"];
        //self.photoLocation = [aDecoder decodeObjectForKey:@"Location"];
        self.isAlbumPreview = [aDecoder decodeBoolForKey:@"AlbumPreview"];
        self.isFavoritePreview = [aDecoder decodeBoolForKey:@"FavoritePreview"];
        self.thumbnailNeedsRedraw = [aDecoder decodeBoolForKey:@"ThumbnailNeedsRedraw"];
        self.photoFavorited = [aDecoder decodeBoolForKey:@"Favorited"]; //cjm favorites
        self.selectCoverHidden = YES;
        self.originalAlbum = [aDecoder decodeObjectForKey:@"OriginalAlbum"];
        
        if (!self.isAlbumPreview)
            self.isAlbumPreview = NO;
        
        if (!self.isFavoritePreview)
            self.isFavoritePreview = NO;
        
        if (!self.photoFavorited)
            self.photoFavorited = NO;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.name forKey:@"Name"];
    [aCoder encodeBool:self.local forKey:@"Local"];
    [aCoder encodeObject:self.photoID forKey:@"photoID"];
    [aCoder encodeObject:self.photoTitle forKey:@"Title"];
    [aCoder encodeObject:self.photoNote forKey:@"Note"];
    [aCoder encodeObject:self.photoCreationDate forKey:@"CreationDate"];
    //[aCoder encodeObject:self.photoLocation forKey:@"Location"];
    [aCoder encodeBool:self.isAlbumPreview forKey:@"AlbumPreview"];
    [aCoder encodeBool:self.isFavoritePreview forKey:@"FavoritePreview"];
    [aCoder encodeBool:self.thumbnailNeedsRedraw forKey:@"ThumbnailNeedsRedraw"];
    [aCoder encodeBool:self.photoFavorited forKey:@"Favorited"]; //cjm favorites
    [aCoder encodeObject:self.originalAlbum forKey:@"OriginalAlbum"];
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.photoID = [NSUUID UUID];
    }
    return self;
}

- (NSString *)fileName {
    return [self.photoID UUIDString];
}

- (NSString *)thumbnailFileName {
    return [[self fileName] stringByAppendingString:@"_sm"];
}

#pragma mark - Selected

- (void)toggleSelectCoverHidden {
    self.selectCoverHidden = !self.selectCoverHidden;
}

@end
