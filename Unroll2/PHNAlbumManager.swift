//
//  PHNAlbumManager.swift
//  Unroll2
//
//  Created by Curtis McCarthy on 7/1/19.
//  Copyright © 2019 Bluewraith. All rights reserved.
//

import UIKit

let CJMAlbumFileName = "Unroll.plist"

class PHNAlbumManager: NSObject, PHNPhotoAlbumDelegate {
    static let sharedInstance = PHNAlbumManager()
    
    //MARK: - Properties
    lazy var fileSerializer = PHNFileSerializer()
    
    private lazy var allAlbumsEdit: [PHNPhotoAlbum] = { //was NSMutableOrderedSet
        /*
        if let set = fileSerializer.readObjectFromRelativePath(CJMAlbumFileName) as? [PHNPhotoAlbum] {
            #if DEBUG
            print("PHNPhotoAlbums fetched for album manager.")
            #endif
            return set
        }
        return []
*/
        // PHASE OUT - model type transitions following Swift migration. Established post v2.1. Replace with above.
        let set = fileSerializer.readObjectFromRelativePath(CJMAlbumFileName)
        if set is [PHNPhotoAlbum] {
            print("set is [PHNPhotoAlbum]")
            return (set as! [PHNPhotoAlbum])
        } else if set is NSMutableOrderedSet {
            print("set is nsmutableorderedset")
            if let arr = (set as! NSMutableOrderedSet).array as? [PHNPhotoAlbum] {
                return arr
            }
        }
        return []
    }()
    
    var allAlbums: [PHNPhotoAlbum] {
        var fullArray = Array(allAlbumsEdit)
        
        if let qn = existingAlbum(named: "CJMQuickNote"), let index = fullArray.firstIndex(of: qn) {
            fullArray.remove(at: index)
        }
        let newArray = Array(fullArray)
        
        return newArray
    }
    
    var _favAlbumEdit: PHNPhotoAlbum?
    var favAlbumEdit: PHNPhotoAlbum {
        if _favAlbumEdit == nil {
            if let favAlbum = existingAlbum(named: "Favorites") {
                _favAlbumEdit = favAlbum
            } else {
                let album = PHNPhotoAlbum(withName: "Favorites", andNote: "Your favorite Photo Notes.  \n\nNote: Changes made here will apply to the Photo Notes in their original albums as well.")
                _favAlbumEdit = album
            }
            _favAlbumEdit?.delegate = self
        }
        return _favAlbumEdit!
    }
    var favPhotosAlbum: PHNPhotoAlbum? {
        let albumCopy = favAlbumEdit
        return albumCopy
    }
    
    /// Returns existing QuickNote album, or instantiates and returns a new one.
    var userQuickNote: PHNPhotoAlbum {
        guard let quickNote = existingAlbum(named: "CJMQuickNote") else {
            let newQuickNote = PHNPhotoAlbum(withName: "CJMQuickNote")
            let photoNote = PhotoNote()
            photoNote.setInitialValuesWithAlbum(newQuickNote.albumTitle)
            newQuickNote.add(photoNote)
            addAlbum(newQuickNote)
            return newQuickNote
        }
        return quickNote
    }
    
    //MARK: - Set Up
    override init() {
        super.init()
        registerDefaults()
        handleFirstLaunch()
    }
    
    func handleFirstLaunch() {
        let firstTime = UserDefaults.standard.bool(forKey: "FirstTime")
        let favorites = UserDefaults.standard.bool(forKey: "FavoritesReserved")
        
        if firstTime {
            let album = PHNPhotoAlbum(withName: "My Photo Notes",
                                       andNote: "Tap Edit to customize the album name and note.")
            addAlbum(album)
            UserDefaults.standard.set(false, forKey: "FirstTime")
        }
        if !favorites {
            if let userFavorites = existingAlbum(named: "Favorites") {
                userFavorites.albumTitle = "My Favorites"
                save()
            }
            UserDefaults.standard.set(true, forKey: "FavoritesReservered")
        }
    }
    
    func registerDefaults() {
        let defaults = [ "FirstTime"         : true,
                         "FavoritesReserved" : false,
                         "QuickNoteMade"     : false ]
        UserDefaults.standard.register(defaults: defaults)
    }
    
    //MARK: - Modifiers
    func addAlbum(_ album: PHNPhotoAlbum) {
        if album.albumTitle == "Favorites" {
            allAlbumsEdit.insert(favAlbumEdit, at: 0)
        } else if album.albumTitle == "CJMQuickNote" {
            allAlbumsEdit.insert(album, at: allAlbumsEdit.count)
        } else {
            allAlbumsEdit.append(album)
        }
        save()
    }
    
    func removeAlbum(_ doomedAlbum: PHNPhotoAlbum) {
        for (index, album) in allAlbumsEdit.enumerated() {
            if album === doomedAlbum {
                removeAlbumAtIndex(index)
                break
            }
        }
    }
    
    func removeAlbumAtIndex(_ index: Int) {
        let doomedAlbum = allAlbumsEdit[index]
        albumWithName(doomedAlbum.albumTitle, deleteImages: doomedAlbum.albumPhotos)
        allAlbumsEdit.remove(at: index)
        checkFavoriteCount()
    }
    
    
    func albumWithName(_ albumName: String, removeImageWithUUID fileName: String) {
        guard let shrinkingAlbum = existingAlbum(named: albumName) else { return }
        
        for photoNote in shrinkingAlbum.albumPhotos {
            if photoNote.fileName == fileName {
                shrinkingAlbum.remove(photoNote)
                break
            }
        }
    }
    
    /// Removes each PhotoNote in the images array from the original and favorites albums, then deletes the PhotoNote from disk.
    func albumWithName(_ name: String, deleteImages images: [PhotoNote]) {
        guard let album = existingAlbum(named: name) else { return }
        
        for doomedImage in images.reversed() {
            PHNServices.sharedInstance.deleteImageFrom(photoNote: doomedImage)
            if doomedImage.photoFavorited {
                if album.albumTitle != "Favorites" {
                    favPhotosAlbum?.remove(doomedImage)
                    album.remove(doomedImage)
                } else {
                    albumWithName(doomedImage.originalAlbum!, removeImageWithUUID: doomedImage.fileName)
                    album.remove(doomedImage)
                }
            } else {
                album.remove(doomedImage)
            }
        }
    }
    
    func replaceAlbumAtIndex(_ atIndex: Int, withAlbumAtIndex fromIndex: Int) {
        // TODO remove the need to do this quick note shuffle.
        let qn = userQuickNote
        let qnIndex = allAlbumsEdit.firstIndex(of: qn)!
        allAlbumsEdit.remove(at: qnIndex)
        allAlbumsEdit.insert(qn, at: allAlbumsEdit.count)
        
        let movingAlbum = allAlbums[fromIndex]
        allAlbumsEdit.remove(at: fromIndex)
        allAlbumsEdit.insert(movingAlbum, at: atIndex)
    }
    
    //MARK: - Requests
    @discardableResult
    func save() -> Bool {
        return fileSerializer.writeObject(allAlbumsEdit, toRelativePath: CJMAlbumFileName)
    }
    
    func existingAlbum(named: String) -> PHNPhotoAlbum? {
        for album in allAlbumsEdit {
            if album.albumTitle == named {
                return album
            }
        }
        return nil
    }
    
    func albumWithName(_ name: String, createPreviewFromImage image: PhotoNote) {
        guard let album = existingAlbum(named: name) else { return }
        if album === favPhotosAlbum {
            album.albumPreviewImage?.isFavoritePreview = false
            image.isAlbumPreview = true
        } else {
            album.albumPreviewImage?.isAlbumPreview = false
            image.isAlbumPreview = true
        }
        album.albumPreviewImage = image
    }
    
    func albumWithName(_ name: String, returnImageAtIndex index: Int) -> PhotoNote? {
        guard let album = existingAlbum(named: name) else { return nil }
        
        if album.albumPhotos.count < (index + 1) {
            return nil
        } else {
            return album.albumPhotos[index]
        }
    }

    //MARK: - PHNPhotoAlbumDelegate
    
    /**
     Check the count of photo notes in the Favorites album, and conditionally add/remove from allAlbumsEdit when necessary.
     
     If there's at least one favorited photo note, add the favorites album to allAlbums if not already present.
     
     If there are zero favorited photo notes, remove the favorites album from allAlbums if it is present.
 */
    func checkFavoriteCount() {
        if let favorites = favPhotosAlbum {
            if favorites.albumPhotos.count < 1 { // if Favorites exists but there are no favorited photos...
                removeAlbum(favorites)
                _favAlbumEdit = nil
            } else if favorites.albumPhotos.count == 1 {
                if !allAlbumsEdit.contains(favorites) {
                    addAlbum(favorites)
                }
            }
        }
    }
}
