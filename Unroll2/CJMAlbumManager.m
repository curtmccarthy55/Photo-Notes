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

@property (nonatomic) NSMutableOrderedSet *allAlbumsEdit; //a set contains unique objects and can't be added more than once
@property (nonatomic) CJMFileSerializer *fileSerializer;

@end

@implementation CJMAlbumManager

+ (instancetype)sharedInstance
{
    /*
     * this dispatch_once macro creats a static token object which ensures the code contained within
     * the block ^{ [code] } will never be run more than once - without this there is, albeit a very unlikely case, that
     * the code inside this method is called several times, resulting in an undefined outcome.
     
     * when you have a 'sharedInstance' (seen in things like [NSNotificationCenter defaultCenter], [NSFileManager defaultManager], [UIApplication sharedAppication]) the instance is created the first time its
     * requested, and will stick around for the life of the application.
     */
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedInstance = [CJMAlbumManager new];
    });
    
    return __sharedInstance;
    
    
//    static CJMAlbumManager *albumStore;
//    
//    if (!albumStore) {
//        albumStore = [[self alloc] initPrivate];
//    }
//    
//    return albumStore;
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        _fileSerializer = [CJMFileSerializer new];
        
    }
    return self;
}


#pragma mark - Album Management

- (NSArray *)allAlbums
{
    return [self.allAlbumsEdit array];
}

- (void)addAlbum:(CJMPhotoAlbum *)album
{
    [self.allAlbumsEdit addObject:album];
}

- (void)removeAlbumAtIndex:(NSUInteger)index
{
    CJMPhotoAlbum *doomedAlbum = [self.allAlbumsEdit objectAtIndex:index];
    
    for (CJMImage *cjmImage in doomedAlbum.albumPhotos) {
    [[CJMServices sharedInstance] deleteImage:cjmImage];
    }
    
    [self.allAlbumsEdit removeObjectAtIndex:index];
}

- (void)replaceAlbumAtIndex:(NSInteger)index withAlbum:(CJMPhotoAlbum *)album
{
    [self.allAlbumsEdit removeObjectAtIndex:index];
    [self.allAlbumsEdit insertObject:album atIndex:index];
}

- (BOOL)containsAlbumNamed:(NSString *)name
{
    __block BOOL exists = NO;
    
    [self.allAlbumsEdit enumerateObjectsUsingBlock:^(CJMPhotoAlbum *obj, NSUInteger idx, BOOL *stop) {
        *stop = [[obj albumTitle] isEqualToString:name];
        exists = *stop;
    }];
    
    return exists;
}

- (void)removeImageWithUUID:(NSString *)fileName fromAlbum:(NSString *)albumName
{
    CJMPhotoAlbum *shrinkingAlbum = [self scanForAlbumWithName:albumName];
    
    for (CJMImage *cjmImage in shrinkingAlbum.albumPhotos) {
        if ([cjmImage.fileName isEqualToString:fileName]) {
            [shrinkingAlbum removeCJMImage:cjmImage];
            break;
        }
    }
}

- (NSMutableOrderedSet *)allAlbumsEdit
{
    if(!_allAlbumsEdit)
    {
        //this is lazy loading from disk
        NSOrderedSet *set = [self.fileSerializer readObjectFromRelativePath:CJMAlbumFileName];
        _allAlbumsEdit = [NSMutableOrderedSet new];
        
        if(set)
            [_allAlbumsEdit addObjectsFromArray:[set array]];
    }
    return _allAlbumsEdit;
}


- (CJMPhotoAlbum *)scanForAlbumWithName:(NSString *)name
{
    CJMPhotoAlbum *foundAlbum;
    
    for (CJMPhotoAlbum *album in _allAlbumsEdit) {
        if ([album.albumTitle isEqualToString:name]) {
            foundAlbum = album;
            break;
        }
    }
    return foundAlbum;
}


#pragma mark - requests to album manager

- (void)albumWithName:(NSString *)name createPreviewFromCJMImage:(CJMImage *)image
{
    CJMPhotoAlbum *album = [self scanForAlbumWithName:name];
    
    album.albumPreviewImage = image;
}

- (CJMImage *)albumWithName:(NSString *)name returnImageAtIndex:(NSInteger)index
{
    
    CJMPhotoAlbum *album = [self scanForAlbumWithName:name];
    
    if (album.albumPhotos.count < index + 1) {
        return nil;
    } else {
        return album.albumPhotos[index];
    }
}

#pragma mark - album saving

- (BOOL)save
{
    return [self.fileSerializer writeObject:self.allAlbumsEdit toRelativePath:CJMAlbumFileName];
}

@end
