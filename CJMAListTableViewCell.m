//
//  CJMAListTableViewCell.m
//  Unroll
//
//  Created by Curt on 4/12/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import "CJMAListTableViewCell.h"
#import "CJMPhotoAlbum.h"
#import "CJMServices.h"

@implementation CJMAListTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configureTextForCell:(CJMAListTableViewCell *)cell withAlbum:(CJMPhotoAlbum *)album {
    cell.cellAlbumName.text = album.albumTitle;
    
    if (album.albumPhotos.count == 0) {
        cell.cellAlbumCount.text = @"No Photos";
    } else if (album.albumPhotos.count == 1) {
        cell.cellAlbumCount.text = @"1 Photo";
    } else {
        cell.cellAlbumCount.text = [NSString stringWithFormat:@"%lu Photos", (unsigned long)album.albumPhotos.count];
    }
}

- (void)configureThumbnailForCell:(CJMAListTableViewCell *)cell forAlbum:(CJMPhotoAlbum *)album {
    [[CJMServices sharedInstance] fetchThumbnailForImage:album.albumPreviewImage
                                                 handler:^(UIImage *thumbnail) {
                                                     cell.cellThumbnail.image = thumbnail;
                                                 }];
    if (cell.cellThumbnail.image == nil) {
        if (album.albumPhotos.count >= 1) {
            CJMImage *firstImage = album.albumPhotos[0];
            [[CJMServices sharedInstance] fetchThumbnailForImage:firstImage handler:^(UIImage *thumbnail) {
                cell.cellThumbnail.image = thumbnail;
            }];
        } else {
            cell.cellThumbnail.image = [UIImage imageNamed:@"no_image.jpg"];
        }
    }
}


@end
