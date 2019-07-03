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
#import "CJMCache.h"

#import "mach/mach.h"

static CJMServices *__sharedInstance;

@interface CJMServices()

@property (nonatomic) CJMCache *cache;
@property (nonatomic) CJMFileSerializer *fileSerializer;
@property (nonatomic) NSTimer *debug_memoryReportingTimer; //cjm 09/05

@end

@implementation CJMServices

// static let sharedInstance = PHNServices()
+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedInstance = [CJMServices new];
    });
    
    return __sharedInstance;
}

/// default initializer suffices
- (instancetype)init
{
    self = [super init];
    if(self) {
        self.cache = [[CJMCache alloc] init];
        self.fileSerializer = [[CJMFileSerializer alloc] init];
    }
    return self;
}

# pragma mark - Internal

// func fetchImageWithName(_ name: String, asData: Bool, handler: CJMImageCompletionHandler?) {
- (void)fetchimageWithName:(NSString *)name asData:(BOOL)asData handler:(CJMImageCompletionHandler)handler {
    if([self.cache objectForKey:name]) {
        handler([self.cache objectForKey:name]);
    } else {
        UIImage *returnImage = nil;
        
        if(asData) {
            returnImage = [self.fileSerializer readImageFromRelativePath:name];
        } else {
            returnImage = [self.fileSerializer readObjectFromRelativePath:name];
        }
        
        if(returnImage) {
            [self.cache setObject:returnImage forKey:name];
        } else {
            returnImage = [UIImage imageNamed:@"No Image"];
        }
        
        if(handler)
            handler(returnImage);
    }
}

// func deleteImageFrom(photoNote: PhotoNote) {
- (void)deleteImage:(CJMImage *)userImage {
    if ([self.cache objectForKey:userImage.fileName]) {
        [self.cache removeObjectForKey:userImage.fileName];
    }
    
    if ([self.cache objectForKey:userImage.thumbnailFileName]) {
        [self.cache removeObjectForKey:userImage.thumbnailFileName];
    }
    
    [self.fileSerializer deleteImageWithFileName:userImage.fileName];
}

// func removeImageFromCache(_ photoNote: PhotoNote) {
- (void)removeImageFromCache:(CJMImage *)image {
    if ([self.cache objectForKey:image.fileName]) {
        [self.cache removeObjectForKey:image.fileName];
    }
    
    if ([self.cache objectForKey:image.thumbnailFileName]) {
        [self.cache removeObjectForKey:image.thumbnailFileName];
    }
}

# pragma mark - Interface
// func fetchUserAlbums(handler: CJMCompletionHandler?) {
- (void)fetchUserAlbums:(CJMCompletionHandler)handler
{
    if(handler)
        handler([[CJMAlbumManager sharedInstance] allAlbums]);
}

#pragma mark - Image fetching and deletion
// func fetchImage(photoNote: PhotoNote, handler: CJMImageCompletionHandler?) {
- (void)fetchImage:(CJMImage *)image handler:(CJMImageCompletionHandler)handler
{
    return [self fetchimageWithName:image.fileName asData:YES handler:handler];
}
// func fetchThumbnailForImage(photoNote: PhotoNote, handler: CJMImageCompletionHandler?) {
- (void)fetchThumbnailForImage:(CJMImage *)image handler:(CJMImageCompletionHandler)handler
{
    return [self fetchimageWithName:image.thumbnailFileName asData:NO handler:handler];
}
// func saveApplicationData() -> Bool {
- (BOOL)saveApplicationData
{
    BOOL savedAlbums = [[CJMAlbumManager sharedInstance] save];
    return savedAlbums; 
}

@end

@implementation CJMServices (Debugging)
// func beginReportingMemoryToConsole(withInterval interval: TimeInterval) {
- (void)beginReportingMemoryToConsoleWithInterval:(NSTimeInterval)interval
{ //cjm 09/05
    if(self.debug_memoryReportingTimer)
        [self endReportingMemoryToConsole];
        
    [self memoryReportingTic];//call the first time
    
    self.debug_memoryReportingTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(memoryReportingTic) userInfo:nil repeats:YES];
}
// func endReportingMemoryToConsole() {
- (void)endReportingMemoryToConsole
{
    [self.debug_memoryReportingTimer invalidate];
    self.debug_memoryReportingTimer = nil;
}

# pragma mark - Memory
// func memoryReportingTic()
- (void)memoryReportingTic
{
    [self reportMemoryToConsoleWithReferrer:@"Memory Report Loop"];
}

#ifdef DEBUG
// func reportMemoryToConsole(withReferrer: String) {
- (void)reportMemoryToConsoleWithReferrer:(NSString *)referrer
{ //cjm 09/05
    struct task_basic_info kerBasicInfo;
    mach_msg_type_number_t kerBasicSize = sizeof(kerBasicInfo);
    kern_return_t kerBasic = task_info(mach_task_self(),
                                       TASK_BASIC_INFO,
                                       (task_info_t)&kerBasicInfo,
                                       &kerBasicSize);
    
    struct task_kernelmemory_info kerMemInfo;
    mach_msg_type_number_t kerMemSize = sizeof(kerMemInfo);
    kern_return_t kerMem = task_info(mach_task_self(),
                                     TASK_KERNELMEMORY_INFO,
                                     (task_info_t)&kerMemInfo,
                                     &kerMemSize);
    
    if(kerBasic == KERN_SUCCESS && kerMem == KERN_SUCCESS) {
       NSLog(@"∆•∆ %@ : \n\
                 resident_size: %.2f MB virtual_size: %.2f MB\n\
                 private alloc: %.2f MB free: %.2f MB\n\
                 shared alloc: %.2f MB free: %.2f MB",
                 referrer, (float)kerBasicInfo.resident_size/(1024.f*1024.f), (float)kerBasicInfo.virtual_size/(1024.f*1024.f),
                 (float)kerMemInfo.total_palloc/(1024.f*1024.f), (float)kerMemInfo.total_pfree/(1024.f*1024.f),
                 (float)kerMemInfo.total_salloc/(1024.f*1024.f), (float)kerMemInfo.total_sfree/(1024.f*1024.f));
 
    } else {
        NSLog(@"∆•∆ %@ : Error with task_info(): %s", referrer, mach_error_string(kerBasic));
    }
}
#else
//if not in debug mode, lets collect less information & by default not print to console, print to crash reporting framework
// func reportMemoryToConsole(withReferrer: String) {
- (void)reportMemoryToConsoleWithReferrer:(NSString *)referrer
{
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(),
                                   TASK_BASIC_INFO,
                                   (task_info_t)&info,
                                   &size);
    
    if(kerr == KERN_SUCCESS)
        NSLog(@"∆•∆ %@ : resident_size: %.2f MB virtual_size: %.2f mb", referrer, (float)info.resident_size/(1024.f*1024.f), (float)info.virtual_size/(1024.f*1024.f));
    else
        NSLog(@"∆•∆ %@ : Error with task_info(): %s", referrer, mach_error_string(kerr));
}
#endif

@end
