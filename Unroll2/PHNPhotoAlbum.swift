//
//  PHNPhotoAlbum.swift
//  Unroll2
//
//  Created by Curtis McCarthy on 7/1/19.
//  Copyright © 2019 Bluewraith. All rights reserved.
//

import UIKit

protocol PHNPhotoAlbumDelegate: class {
    func checkFavoriteCount()
}

class PHNPhotoAlbum: NSObject, NSCoding, NSCopying {
    var albumTitle: String
    var albumNote: String?
//    var privateAlbum = false //TODO: implement private albums.
    var albumPhotos: [PhotoNote] {
        return Array(albumEditablePhotos)
    }
    private var albumEditablePhotos = [PhotoNote]() //was NSMutableOrderedSet
    var albumPreviewImage: PhotoNote?
    weak var delegate: PHNPhotoAlbumDelegate?
    
    //MARK: - Set up
    
    init(withName name: String, andNote note: String?) {
        albumTitle = name
        albumNote = note
        super.init()
    }
    
    convenience init(withName name: String) {
        self.init(withName: name, andNote: nil)
    }
    
    //MARK: - Requests
    func checkFavoriteCount() {
        
    }
    
    func add(_ photoNote: PhotoNote) {
        albumEditablePhotos.append(photoNote)
        if albumTitle == "Favorites" {
            delegate?.checkFavoriteCount()
        }
    }
    
    /// Search for and remove the passed in PhotoNote.
    func remove(_ photoNote: PhotoNote) {
        for (index, item) in albumEditablePhotos.enumerated() {
            if item === photoNote {
                albumEditablePhotos.remove(at: index)
                break
            }
        }
    }
    
    func addMultiple(_ photoNotes: [PhotoNote]) {
        // Sort by ascending creation date.
        let sortedNewImages = photoNotes.sorted { $0.photoCreationDate! < $1.photoCreationDate! }
        albumEditablePhotos.append(contentsOf: sortedNewImages)
    }
    
    func removeAtIndices(_ indcies: IndexSet) {
        
    }
    
    func description() -> String {
        return String(format: "PHNPhotoAlbum with name %@, memAddress: %p, and photoCount: %lu", albumTitle, self, albumEditablePhotos.count)
    }
    
    //MARK: - NSCoding & NSCopying
    
    private enum CodingKeys: String, CodingKey {
        case albumTitle = "Title"
        case albumNote = "Note"
        case albumEditablePhotos = "AlbumPhotos"
        case albumPreviewImage = "PreviewImage"
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(albumTitle, forKey: CodingKeys.albumTitle.rawValue)
        aCoder.encode(albumNote, forKey: CodingKeys.albumNote.rawValue)
        aCoder.encode(albumEditablePhotos, forKey: CodingKeys.albumEditablePhotos.rawValue)
        aCoder.encode(albumPreviewImage, forKey: CodingKeys.albumPreviewImage.rawValue)
    }
    
    required init?(coder aDecoder: NSCoder) {
        albumTitle = aDecoder.decodeObject(forKey: CodingKeys.albumTitle.rawValue) as! String
        albumNote = aDecoder.decodeObject(forKey: CodingKeys.albumNote.rawValue) as? String
        albumEditablePhotos = aDecoder.decodeObject(forKey: CodingKeys.albumEditablePhotos.rawValue) as! [PhotoNote]
        albumPreviewImage = aDecoder.decodeObject(forKey: CodingKeys.albumPreviewImage.rawValue) as! PhotoNote
    }
    
    func copy(with zone: NSZone? = nil) -> Any /*PHNPhotoAlbum*/ {
        let albumCopy = PHNPhotoAlbum(withName: albumTitle, andNote: albumNote)
        albumCopy.albumEditablePhotos = albumEditablePhotos
        albumCopy.albumPreviewImage = albumPreviewImage
//        albumCopy.privateAlbum = privateAlbum
        
        return albumCopy
    }
}
