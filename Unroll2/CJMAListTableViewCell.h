//
//  CJMAListTableViewCell.h
//  Unroll
//
//  Created by Curt on 4/12/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CJMPhotoAlbum;

@interface CJMAListTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *cellThumbnail;

- (void)configureWithTitle:(NSString *)albumTitle withAlbumCount:(int)albumCount;
- (void)configureThumbnailForCell:(CJMAListTableViewCell *)cell forAlbum:(CJMPhotoAlbum *)album;

@end
