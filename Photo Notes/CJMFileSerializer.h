//
//  CJMFileSerializer.h
//  Unroll
//
//  Created by Curt on 4/15/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//


@import UIKit;

@interface CJMFileSerializer : NSObject

- (BOOL)writeObject:(id)data toRelativePath:(NSString *)path;
- (id)readObjectFromRelativePath:(NSString *)path;
- (BOOL)writeImage:(UIImage *)image toRelativePath:(NSString *)path;
- (UIImage *)readImageFromRelativePath:(NSString *)path;
- (void)deleteImageWithFileName:(NSString *)fileName;

@end
