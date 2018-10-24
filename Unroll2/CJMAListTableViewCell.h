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
@property (weak, nonatomic) IBOutlet UILabel *cellAlbumName;
@property (weak, nonatomic) IBOutlet UILabel *cellAlbumCount;

- (void)configureTextForCell:(CJMAListTableViewCell *)cell withAlbum:(CJMPhotoAlbum *)album;
- (void)configureThumbnailForCell:(CJMAListTableViewCell *)cell forAlbum:(CJMPhotoAlbum *)album;

@end
