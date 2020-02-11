//
//  PHNImage.swift
//  Unroll2
//
//  Created by Curtis McCarthy on 6/28/19.
//  Copyright © 2019 Bluewraith. All rights reserved.
//

import UIKit

class PhotoNote: NSObject, NSCoding {
    
    //MARK: - Properties
    var name: String?
    var local: Bool?
    
    var photoTitle: String?
    var photoNote: String?
    var photoCreationDate: Date?
//    var photoLocation: CLLocation?
    var photoPrivacy = false
    var photoID: UUID
    var photoKey: String?
    var fileName: String {
        return photoID.uuidString //[self.photoID UUIDString];
    }
    var thumbnailFileName: String {
        return fileName + "_sm"
    }
    var isAlbumPreview = false
    var isFavoritePreview = false
    var thumbnailNeedsRedraw = false
    var selectCoverHidden = true
    weak var photoImage: UIImage?
    var originalAlbum: String?
    var photoFavorited = false
    
    //MARK: - Set Up
    override init() {
        photoID = UUID()
        super.init()
    }
    
    //MARK: - Property Modifiers
    func setInitialValuesWithAlbum(_ album: String) {
        photoTitle = "No Title Created "
        photoNote = "Tap Edit to change the title and note!"
        originalAlbum = album
    }
    
    func toggleSelectCoverHidden() {
        selectCoverHidden = !selectCoverHidden
    }
    
    //MARK: - NSCoding
    private enum CodingKeys: String, CodingKey {
        case name                 = "Name"
        case local                = "Local"
        case photoID
        case title                = "Title"
        case note                 = "Note"
        case photoCreationDate    = "CreationDate"
        case photoLocation        = "Location"
        case isAlbumPreview       = "AlbumPreview"
        case isFavoritePreview    = "FavoritePreview"
        case thumbnailNeedsRedraw = "ThumbnailNeedsRedraw"
        case photoFavorited       = "Favorited"
        case originalAlbum        = "OriginalAlbum"
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: CodingKeys.name.rawValue)
        aCoder.encode(local, forKey: CodingKeys.local.rawValue)
        aCoder.encode(photoID, forKey: CodingKeys.photoID.rawValue)
        aCoder.encode(photoTitle, forKey: CodingKeys.title.rawValue)
        aCoder.encode(photoNote, forKey: CodingKeys.note.rawValue)
        aCoder.encode(photoCreationDate, forKey: CodingKeys.photoCreationDate.rawValue)
//        aCoder.encode(photoLocation, forKey: CodingKeys.photoLocation.rawValue)
        aCoder.encode(isAlbumPreview, forKey: CodingKeys.isAlbumPreview.rawValue)
        aCoder.encode(isFavoritePreview, forKey: CodingKeys.isFavoritePreview.rawValue)
        aCoder.encode(thumbnailNeedsRedraw, forKey: CodingKeys.thumbnailNeedsRedraw.rawValue)
        aCoder.encode(photoFavorited, forKey: CodingKeys.photoFavorited.rawValue)
        aCoder.encode(originalAlbum, forKey: CodingKeys.originalAlbum.rawValue)
    }
    
    required init?(coder aDecoder: NSCoder) {
        name = aDecoder.decodeObject(forKey: CodingKeys.name.rawValue) as? String
        local = aDecoder.decodeObject(forKey: CodingKeys.local.rawValue) as? Bool
        photoID = aDecoder.decodeObject(forKey: CodingKeys.photoID.rawValue) as! UUID
        photoTitle = aDecoder.decodeObject(forKey: CodingKeys.title.rawValue) as? String
        photoNote = aDecoder.decodeObject(forKey: CodingKeys.note.rawValue) as? String
        photoCreationDate = aDecoder.decodeObject(forKey: CodingKeys.photoCreationDate.rawValue) as? Date
//        photoLocation = aDecoder.decodeObject(forKey: CodingKeys.photoLocation.rawValue) as? CLLocation
        isAlbumPreview = aDecoder.decodeObject(forKey: CodingKeys.isAlbumPreview.rawValue) as? Bool ?? false
        isFavoritePreview = aDecoder.decodeObject(forKey: CodingKeys.isFavoritePreview.rawValue) as? Bool ?? false
        thumbnailNeedsRedraw = aDecoder.decodeObject(forKey: CodingKeys.thumbnailNeedsRedraw.rawValue) as? Bool ?? false
        photoFavorited = aDecoder.decodeObject(forKey: CodingKeys.photoFavorited.rawValue) as? Bool ?? false
        originalAlbum = aDecoder.decodeObject(forKey: CodingKeys.originalAlbum.rawValue) as? String
    }
}
