//
//  CJMAlbumStore.m
//  Unroll
//
//  Created by Curt on 4/12/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import "CJMAlbumManager.h"
#import "CJMFileSerializer.h"
#import "CJMServices.h"
#import "CJMImage.h"

#define CJMAlbumFileName @"Unroll.plist"

static CJMAlbumManager *__sharedInstance;

@interface CJMAlbumManager ()

@property (nonatomic, strong) NSMutableOrderedSet *allAlbumsEdit;
@property (nonatomic, strong) CJMPhotoAlbum *favAlbumEdit; //cjm favorites album
@property (nonatomic) CJMFileSerializer *fileSerializer;

@end

@implementation CJMAlbumManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedInstance = [CJMAlbumManager new];
    });
    return __sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.fileSerializer = [CJMFileSerializer new];
        [self registerDefaults];
        [self handleFirstTime];
    }
    return self;
}

- (void)handleFirstTime {
    BOOL firstTime = [[NSUserDefaults standardUserDefaults] boolForKey:@"FirstTime"];
    BOOL favorites = [[NSUserDefaults standardUserDefaults] boolForKey:@"FavoritesReserved"];
    BOOL quickNote = [[NSUserDefaults standardUserDefaults] boolForKey:@"QuickNoteMade"];
    
    if (firstTime) {
        CJMPhotoAlbum *album = [[CJMPhotoAlbum alloc] initWithName:@"My Photo Notes" andNote:@"Tap Edit to customize the name and note sections."];
        [self addAlbum:album];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"FirstTime"];
    }
    if (!favorites) {
        if ([self containsAlbumNamed:@"Favorites"]) {
            CJMPhotoAlbum *userFavorites = [self scanForAlbumWithName:@"Favorites"];
            [userFavorites setAlbumTitle:@"My Favorites"];
            [self save];
        }
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"FavoritesReserved"];
    }
    if (!quickNote) { //cjm 01/03
        CJMPhotoAlbum *quickNoteAlbum = [self userQuickNote];
        [self addAlbum:quickNoteAlbum];
        [self save];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"QuickNoteMade"];
    }
}

- (void)registerDefaults {
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{ @"FirstTime" : @YES , @"FavoritesReserved" : @NO , @"QuickNoteMade" : @NO }];
}

#pragma mark - Content

- (NSArray *)allAlbums { //cjm 01/02
    NSMutableArray *fullArray = [NSMutableArray arrayWithArray:[self.allAlbumsEdit array]];
    [fullArray removeObject:[self scanForAlbumWithName:@"CJMQuickNote"]];
    NSArray *newArray = [NSArray arrayWithArray:fullArray];
    
    return newArray;
//    return [self.allAlbumsEdit array];
}


- (NSMutableOrderedSet *)allAlbumsEdit {
    if(!_allAlbumsEdit) {
        //lazy load from disk
        NSOrderedSet *set = [self.fileSerializer readObjectFromRelativePath:CJMAlbumFileName];
        _allAlbumsEdit = [NSMutableOrderedSet new];
        
        if (set) {
            [_allAlbumsEdit addObjectsFromArray:[set array]];
        }
    }
    return _allAlbumsEdit;
}

- (CJMPhotoAlbum *)userQuickNote { //cjm 01/03
    CJMPhotoAlbum *album = [self scanForAlbumWithName:@"CJMQuickNote"];
    if (!album) {
        album = [[CJMPhotoAlbum alloc] initWithName:@"CJMQuickNote"];
        [self addAlbum:album];
    }
    
    NSLog(@"*cjm* allAlbums == %@, allAlbumsEdit == %@", self.allAlbums, self.allAlbumsEdit);
    
    return album;
}

- (CJMPhotoAlbum *)favPhotosAlbum {
    CJMPhotoAlbum *albumCopy = self.favAlbumEdit;
    return albumCopy;
}

- (CJMPhotoAlbum *)favAlbumEdit {
    if (!_favAlbumEdit) {
        CJMPhotoAlbum *favAlbum = [self scanForAlbumWithName:@"Favorites"];
        _favAlbumEdit = [CJMPhotoAlbum new];
        
        if (favAlbum) {
            _favAlbumEdit = favAlbum;
        } else {
            CJMPhotoAlbum *album = [[CJMPhotoAlbum alloc] initWithName:@"Favorites" andNote:@"Your favorite Photo Notes coalesced in one spot.  \n\nNote: Changes made here will apply to the Photo Notes in their original albums as well."];
            _favAlbumEdit = album;
        }
        _favAlbumEdit.delegate = self;
    }
    return _favAlbumEdit;
}



#pragma mark - Content management

- (void)addAlbum:(CJMPhotoAlbum *)album {
    if ([album.albumTitle isEqualToString:@"Favorites"]) {
        [self.allAlbumsEdit insertObject:self.favAlbumEdit atIndex:0];
    } else if ([album.albumTitle isEqualToString:@"CJMQuickNote"]) {
        [self.allAlbumsEdit insertObject:album atIndex:self.allAlbumsEdit.count];
    } else {
        [self.allAlbumsEdit addObject:album];
    }
    [self save];
}

- (void)removeAlbumAtIndex:(NSUInteger)index {
    CJMPhotoAlbum *doomedAlbum = [self.allAlbumsEdit objectAtIndex:index];
    [self albumWithName:doomedAlbum.albumTitle deleteImages:doomedAlbum.albumPhotos];
    
    //pre cjm 12/27 testing
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        for (CJMImage *cjmImage in doomedAlbum.albumPhotos) {
//        [[CJMServices sharedInstance] deleteImage:cjmImage];
//        }
//    });
    
    [self.allAlbumsEdit removeObject:doomedAlbum];
    [self checkFavoriteCount];
}

- (void)replaceAlbumAtIndex:(NSInteger)toIndex withAlbumFromIndex:(NSInteger)fromIndex { //cjm 01/04
    CJMPhotoAlbum *uQN = [self userQuickNote];
    [self.allAlbumsEdit removeObject:uQN];
    [self.allAlbumsEdit insertObject:uQN atIndex:self.allAlbumsEdit.count];
    
    CJMPhotoAlbum *movingAlbum = [self.allAlbums objectAtIndex:fromIndex];
    [self.allAlbumsEdit removeObject:movingAlbum];
    [self.allAlbumsEdit insertObject:movingAlbum atIndex:toIndex];
}

- (BOOL)containsAlbumNamed:(NSString *)name {
    __block BOOL exists = NO;
    [self.allAlbumsEdit enumerateObjectsUsingBlock:^(CJMPhotoAlbum *obj, NSUInteger idx, BOOL *stop) {
        *stop = [[obj albumTitle] isEqualToString:name];
        exists = *stop;
    }];
    
    return exists;
}

- (CJMPhotoAlbum *)scanForAlbumWithName:(NSString *)name {
    CJMPhotoAlbum *foundAlbum;
    for (CJMPhotoAlbum *album in self.allAlbumsEdit) {
        if ([album.albumTitle isEqualToString:name]) {
            foundAlbum = album;
            break;
        }
    }
    return foundAlbum;
}

#pragma mark - Requests to album manager

- (void)albumWithName:(NSString *)name createPreviewFromCJMImage:(CJMImage *)image {
    CJMPhotoAlbum *album = [self scanForAlbumWithName:name];
    if (album == self.favPhotosAlbum) {
        [album.albumPreviewImage setIsFavoritePreview:NO];
        [image setIsFavoritePreview:YES];
    } else {
        [album.albumPreviewImage setIsAlbumPreview:NO];
        [image setIsAlbumPreview:YES];
    }
    
    album.albumPreviewImage = image;
}

- (CJMImage *)albumWithName:(NSString *)name returnImageAtIndex:(NSInteger)index {
    CJMPhotoAlbum *album = [self scanForAlbumWithName:name];
    
    if (album.albumPhotos.count < index + 1) {
        return nil;
    } else {
        return album.albumPhotos[index];
    }
}

- (void)albumWithName:(NSString *)albumName removeImageWithUUID:(NSString *)fileName {
    CJMPhotoAlbum *shrinkingAlbum = [self scanForAlbumWithName:albumName];
    
    for (CJMImage *cjmImage in shrinkingAlbum.albumPhotos) {
        if ([cjmImage.fileName isEqualToString:fileName]) {
            [shrinkingAlbum removeCJMImage:cjmImage];
            break;
        }
    }
}

//  cjm 12/27: removes each CJMImage in the images array from the original and favorites albums, then deletes the CJMImage from the disk.
- (void)albumWithName:(NSString *)albumName deleteImages:(NSArray *)images {
    CJMPhotoAlbum *album = [self scanForAlbumWithName:albumName];
    for (CJMImage *doomedImage in images) {
        [[CJMServices sharedInstance] deleteImage:doomedImage];
        if (doomedImage.photoFavorited) {
            if (![album.albumTitle isEqualToString:@"Favorites"]) {
                [self.favPhotosAlbum removeCJMImage:doomedImage];
                [album removeCJMImage:doomedImage];
            } else {
                [self albumWithName:doomedImage.originalAlbum removeImageWithUUID:doomedImage.fileName];
                [album removeCJMImage:doomedImage];
            }
        } else {
            [album removeCJMImage:doomedImage];
        }
    }
}

#pragma mark - PhotoAlbum Delegate

- (void)checkFavoriteCount {
    if (self.favPhotosAlbum.albumPhotos.count < 1) {
        [self.allAlbumsEdit removeObject:self.favAlbumEdit];
    } else if (self.favPhotosAlbum.albumPhotos.count == 1) {
        if (![self.allAlbumsEdit containsObject:self.favAlbumEdit]) {
            [self addAlbum:self.favAlbumEdit];
        }
    }
}

#pragma mark - Album saving

- (BOOL)save {
    return [self.fileSerializer writeObject:self.allAlbumsEdit toRelativePath:CJMAlbumFileName];
}

@end
