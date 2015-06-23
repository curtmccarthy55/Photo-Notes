//
//  CJMImage.h
//  Unroll
//
//  Created by Curt on 4/13/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface CJMImage : NSObject <NSCoding>

@property (nonatomic) NSString *name;
@property (nonatomic) BOOL local;

//- (instancetype)initWithName:(NSString *)name;

@property (nonatomic, strong) NSString *photoTitle;
@property (nonatomic, strong) NSString *photoNote;
@property (nonatomic, strong) NSDate *photoCreationDate;
@property (nonatomic, strong) CLLocation *photoLocation;
@property (nonatomic) BOOL *photoPrivacy;
@property (nonatomic) NSUUID *photoID;
@property (nonatomic, strong) NSString *photoKey;
@property (nonatomic, readonly) NSString *fileName;
@property (nonatomic, readonly) NSString *thumbnailFileName;
@property (nonatomic) BOOL isAlbumPreview;

@property (nonatomic) BOOL selectCoverHidden;

@property (nonatomic, weak) UIImage *photoImage;

- (void)toggleSelectCoverHidden;

@end
