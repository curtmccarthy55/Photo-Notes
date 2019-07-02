//
//  CJMFileSerializer.m
//  Unroll
//
//  Created by Curt on 4/15/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

@import UIKit;
#import "CJMFileSerializer.h"

@implementation CJMFileSerializer

#pragma mark - read/write/delete

// func readObjectFromRelativePath(_ path: String) -> Any? {
- (id)readObjectFromRelativePath:(NSString *)path {
    NSString *absolutePath = [self absolutePathFromRelativePath:path];
    id object = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:absolutePath]) {
        object = [NSKeyedUnarchiver unarchiveObjectWithFile:absolutePath];
    }
    return object;
}

// func readImageFromRelativePath(_ path: String) -> UIImage? {
- (UIImage *)readImageFromRelativePath:(NSString *)path
{
    id data = [self readObjectFromRelativePath:path];
    if(data)
        return [[UIImage alloc] initWithData:data];
    else
        return nil;
}

// func writeObject(_ data: Any?, toRelativePath path: String) -> Bool {
- (BOOL)writeObject:(id)data toRelativePath:(NSString *)path {
    //cjm favorites album [CJMAlbumManager save] calls [fileSerializer writeObject:allAlbumsEdit toRelativePath:@"Unroll.plist"]
    NSString *filePath = [self absolutePathFromRelativePath:path];
    NSLog(@"filePath == %@", filePath);
    return [NSKeyedArchiver archiveRootObject:data toFile:filePath];
}

// func writeImage(_ image: UIImage, toRelativePath path: String) -> Bool {
- (BOOL)writeImage:(UIImage *)image toRelativePath:(NSString *)path
{
    //this method is just to maintain API balance with readImageFromRelativePath
    return [self writeObject:image toRelativePath:path];
}

// func deleteImageWithFileName(_ fileName: String) {
- (void)deleteImageWithFileName:(NSString *)fileName {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *filePath = [self absolutePathFromRelativePath:fileName];
    NSString *thumbnailFilePath = [filePath stringByAppendingString:@"_sm"];
    NSError *error;
    
    BOOL fullImageSuccess = [fileManager removeItemAtPath:filePath error:&error];
    
    if (fullImageSuccess) {
//        NSLog(@"Full image file deleted successfully!");
    } else {
//        NSLog(@"Could not delete full image file: %@", [error localizedDescription]);
    }
    
    BOOL thumbnailSuccess = [fileManager removeItemAtPath:thumbnailFilePath
                                                    error:&error];
    
    if (thumbnailSuccess) {
//        NSLog(@"Thumbnail deleted successfully!");
    } else {
//        NSLog(@"Could not delete thumbnail file: %@", [error localizedDescription]);
    }
    
}

#pragma mark - File pathing
// func documentsDirectory() -> String {
- (NSString *)documentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];

    return documentsDirectory;
}

// func absolutePathFromRelativePath(_ path: String) -> String {
- (NSString *)absolutePathFromRelativePath:(NSString *)path
{
    return [[self documentsDirectory] stringByAppendingPathComponent:path];
}

@end
