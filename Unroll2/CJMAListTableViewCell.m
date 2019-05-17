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

@interface CJMAListTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *cellAlbumName;
@property (weak, nonatomic) IBOutlet UILabel *cellAlbumCount;
@property (weak, nonatomic) IBOutlet UIView *subContentView;

@end

@implementation CJMAListTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
//    self.cellThumbnail.layer.cornerRadius = 4.0;
//    self.cellThumbnail.layer.borderColor = UIColor.grayColor.CGColor;
//    self.cellThumbnail.layer.borderWidth = 1.0;
    self.backgroundColor = UIColor.clearColor;
    self.contentView.backgroundColor = UIColor.clearColor;
    self.subContentView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.90];
    self.subContentView.layer.cornerRadius = 8.0;
    self.subContentView.layer.borderColor = UIColor.blackColor.CGColor;
    self.subContentView.layer.borderWidth = 1.0;
    self.subContentView.clipsToBounds = true;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configureWithTitle:(NSString *)albumTitle withAlbumCount:(int)albumCount {
    self.cellAlbumName.text = albumTitle;
    
    NSString *albumCountText;
    if (albumCount == 0) {
        albumCountText = @"No Photos";
    } else if (albumCount == 1) {
        albumCountText = @"1 Photo";
    } else {
        albumCountText = [NSString stringWithFormat:@"%lu Photos", (unsigned long)albumCount];
    }
    self.cellAlbumCount.text = albumCountText;
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
            cell.cellThumbnail.image = [UIImage imageNamed:@"NoImage"];
        }
    }
    if (@available(iOS 11.0, *)) {
        cell.cellThumbnail.accessibilityIgnoresInvertColors = YES;
    }
}


@end
