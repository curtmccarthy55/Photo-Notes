//
//  PHNPhotoCell.swift
//  Unroll2
//
//  Created by Curtis McCarthy on 7/11/19.
//  Copyright © 2019 Bluewraith. All rights reserved.
//

import UIKit

class PHNPhotoCell: UICollectionViewCell {
    @IBOutlet private weak var cellImage: UIImageView!
    @IBOutlet weak var cellSelectCover: UIView!
    var photoNote: PhotoNote {
        return privatePhotoNote
    }
    private var privatePhotoNote: PhotoNote
    private var thumbnailImage: UIImage?

    func updateWith(photoNote: PhotoNote) {
        privatePhotoNote = photoNote
        PHNServices.sharedInstance.fetchThumbnailForImage(photoNote: privatePhotoNote) { [weak self] (thumbnail) in
            // if thumbnail not properly captured during import, create one.
            if let cThumbnail = thumbnail {
                if cThumbnail.size.width == 0 {
                    self?.privatePhotoNote.thumbnailNeedsRedraw = true
                    PHNServices.sharedInstance.removeImageFromCache(self?.privatePhotoNote)
                } else {
                    self?.cellImage.image = cThumbnail
                }
            }
        }
        
        if #available(iOS 11.0, *) {
            cellImage.accessibilityIgnoresInvertColors = true
        }
    }

}
