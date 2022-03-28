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
//        subContentView.backgroundColor = UIColor(white: 1.0, alpha: 0.9)
        subContentView.layer.cornerRadius = 8.0
        subContentView.layer.borderColor = UIColor.black.cgColor
        subContentView.layer.borderWidth = 1.0
        subContentView.clipsToBounds = true
        
        if #available(iOS 13.0, *) {
            cellAlbumName.textColor = .label
        }
        
        /* ~~~ Add Blur ~~~ */
        // 1. In order for UIVisualEffectView to actually blur the content, its superview must be transparent. To make it transparent, change the background color of view to clear.
        subContentView.backgroundColor = .clear
        // 2. Create a UIBlurEffect with a UIBlurEffect.Style.light style. This defines the blur style. There are many different styles; check the documentation to see the full list.
        let blurEffect = UIBlurEffect(style: .regular)
        // 3. Create a UIVisualEffectView with the blur you just created. This class is a subclass of UIView. Its sole purpose is to define and display complex visual effects.
        let blurView = UIVisualEffectView(effect: blurEffect)
        // 4. Disable translating the auto-resizing masks into constraints on blurView — you’ll manually add constraints in a moment — and add it at the bottom of the view stack. If you added blurView on top of the view, it would blur all the controls underneath it instead!
        blurView.translatesAutoresizingMaskIntoConstraints = false
        subContentView.insertSubview(blurView, at: 0)

        // These constraints keep the frame of blurView consistent with that of OptionsViewController.
        NSLayoutConstraint.activate([
          blurView.topAnchor.constraint(equalTo: subContentView.topAnchor),
          blurView.leadingAnchor.constraint(equalTo: subContentView.leadingAnchor),
          blurView.heightAnchor.constraint(equalTo: subContentView.heightAnchor),
          blurView.widthAnchor.constraint(equalTo: subContentView.widthAnchor)
        ])
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
            PHNServices.shared.fetchThumbnailForImage(photoNote: album.albumPreviewImage!) { [weak self] thumbnail in
                self?.cellThumbnail.image = thumbnail
            }
        }
        
        if cellThumbnail.image == nil {
            if album.albumPhotos.count >= 1 {
                let firstPhoto = album.albumPhotos[0]
                PHNServices.shared.fetchThumbnailForImage(photoNote: firstPhoto) { [weak self] thumbnail in
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
