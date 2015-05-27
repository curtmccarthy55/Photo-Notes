//
//  CJMFileSerializer.h
//  Unroll
//
//  Created by Curt on 4/15/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//


#import <Foundation/Foundation.h>

@interface CJMFileSerializer : NSObject

- (BOOL)writeObject:(id)data toRelativePath:(NSString *)path;

- (id)readObjectFromRelativePath:(NSString *)path;

@end
