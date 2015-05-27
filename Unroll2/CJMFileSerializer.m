//
//  CJMFileSerializer.m
//  Unroll
//
//  Created by Curt on 4/15/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import "CJMFileSerializer.h"

@implementation CJMFileSerializer

- (BOOL)writeObject:(id)data toRelativePath:(NSString *)path
{
    return [NSKeyedArchiver archiveRootObject:data toFile:[self absolutePathFromRelativePath:path]];
}

- (id)readObjectFromRelativePath:(NSString *)path
{
    NSString *absolutePath = [self absolutePathFromRelativePath:path];
    id object = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:absolutePath]) {
        object = [NSKeyedUnarchiver unarchiveObjectWithFile:absolutePath];
    }
    return object;
}

- (NSString *)documentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    return documentsDirectory;
}

- (NSString *)absolutePathFromRelativePath:(NSString *)path
{
    return [[self documentsDirectory] stringByAppendingPathComponent:path];
}

@end
