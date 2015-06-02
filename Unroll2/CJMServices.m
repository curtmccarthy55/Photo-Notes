//
//  CJMServices.m
//  Unroll
//
//  Created by Curt on 4/15/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import "CJMServices.h"
#import "CJMPhotoAlbum.h"
#import "CJMImage.h"
#import "CJMFileSerializer.h"

static CJMServices *__sharedInstance;

@interface CJMServices()

@property (nonatomic) NSCache *cache;
@property (nonatomic) CJMFileSerializer *fileSerializer;
@end

@implementation CJMServices


+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedInstance = [CJMServices new];
    });
    
    return __sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if(self)
    {
        //initialize anything neccessary
        _cache = [[NSCache alloc] init];
        _fileSerializer = [[CJMFileSerializer alloc] init];
    }
    return self;
}

# pragma mark - Internal

- (void)fetchimageWithName:(NSString *)name handler:(CJMImageCompletionHandler)handler
{
    if([self.cache objectForKey:name])
        handler([self.cache objectForKey:name]);
    else
    {
        UIImage *returnImage = [self.fileSerializer readObjectFromRelativePath:name];
        if(returnImage) {
            [self.cache setObject:returnImage forKey:name];
        }
        else {
            returnImage = [UIImage imageNamed:@"No Image"];
        }
        if(handler)
            handler(returnImage);
    }
}

- (void)deleteImage:(CJMImage *)userImage
{
    if ([self.cache objectForKey:userImage.fileName]) {
        [self.cache removeObjectForKey:userImage.fileName];
    }
    
    if ([self.cache objectForKey:userImage.thumbnailFileName]) {
        [self.cache removeObjectForKey:userImage.thumbnailFileName];
    }
    
    [self.fileSerializer deleteImageWithFileName:userImage.fileName];
}

# pragma mark - Interface

- (void)fetchUserAlbums:(CJMCompletionHandler)handler
{
    if(handler)
        handler([[CJMAlbumManager sharedInstance] allAlbums]);
}

#pragma mark - Image fetching and deletion

- (void)fetchImage:(CJMImage *)image handler:(CJMImageCompletionHandler)handler
{
    return [self fetchimageWithName:image.fileName handler:handler];
}

- (void)fetchThumbnailForImage:(CJMImage *)image handler:(CJMImageCompletionHandler)handler
{
    return [self fetchimageWithName:image.thumbnailFileName handler:handler];
}

- (BOOL)saveApplicationData
{
    BOOL savedAlbums = [[CJMAlbumManager sharedInstance] save];
    return savedAlbums; 
}

@end
