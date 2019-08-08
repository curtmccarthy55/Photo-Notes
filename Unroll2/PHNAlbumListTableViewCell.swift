//
//  PHNAlbumListTableViewCell.swift
//  Unroll2
//
//  Created by Curtis McCarthy on 7/3/19.
//  Copyright © 2019 Bluewraith. All rights reserved.
//

import UIKit

class PHNAlbumListTableViewCell: UITableViewCell {
    @IBOutlet weak var cellThumbnail: UIImageView!
    @IBOutlet weak var cellAlbumName: UILabel!
//    @IBOutlet weak var cellAlbumCount: UILabel!
    @IBOutlet weak var subContentView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        subContentView.backgroundColor = UIColor(white: 1.0, alpha: 0.9)
        subContentView.layer.cornerRadius = 8.0
        subContentView.layer.borderColor = UIColor.black.cgColor
        subContentView.layer.borderWidth = 1.0
        subContentView.clipsToBounds = true
    }

    func configureWithTitle(_ title: String, count: Int) {
        cellAlbumName.text = title
        
        /* Removing cellAlbumCount label, perhaps permanently.
        var albumCountText: String
        if count == 0 {
            albumCountText = "No Photo Notes"
        } else if count == 1 {
            albumCountText = "1 Photo Note"
        } else {
            albumCountText = "\(count) Photo Notes"
        }
        cellAlbumCount.text = albumCountText
 */
    }
    
    func configureThumbnail(forAlbum album: PHNPhotoAlbum) {
        if album.albumPreviewImage != nil {
            PHNServices.sharedInstance.fetchThumbnailForImage(photoNote: album.albumPreviewImage!) { [weak self] thumbnail in
                self?.cellThumbnail.image = thumbnail
            }
        }
        
        if cellThumbnail.image == nil {
            if album.albumPhotos.count >= 1 {
                let firstPhoto = album.albumPhotos[0]
                PHNServices.sharedInstance.fetchThumbnailForImage(photoNote: firstPhoto) { [weak self] thumbnail in
                    self?.cellThumbnail.image = thumbnail
                }
            } else {
                cellThumbnail.image = UIImage(named: "NoImage")
            }
        }
        if #available(iOS 11.0, *) {
            self.cellThumbnail.accessibilityIgnoresInvertColors = true
        }
    }
}
