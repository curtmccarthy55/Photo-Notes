//
//  PHNGrabCell.swift
//  Unroll2
//
//  Created by Curtis McCarthy on 8/2/19.
//  Copyright © 2019 Bluewraith. All rights reserved.
//

import UIKit
import Photos

class PHNGrabCell: UICollectionViewCell {
    @IBOutlet weak var cellSelectCover: UIView!
    @IBOutlet weak var cellImage: UIImageView!
    var asset: PHAsset?
    var thumbnailImage: UIImage?
}
