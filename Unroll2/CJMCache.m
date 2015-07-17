//
//  CJMCache.m
//  Photo Notes
//
//  Created by Curt on 7/12/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import "CJMCache.h"
@import UIKit;

@implementation CJMCache

- (id)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAllObjects) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

@end
