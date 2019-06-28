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
    /*
    - (void)toggleSelectCoverHidden;
    - (void)setInitialValuesForCJMImage:(CJMImage *)cjmImage inAlbum:(NSString *)album;
 */
    //MARK: - Set up
    override init() {
        photoID = UUID()
        super.init()
    }
    
    //MARK: - Property modifiers
    //previously - (void)setInitialValuesForCJMImage:(CJMImage *)cjmImage inAlbum:(NSString *)album
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
    /*
     - (void)encodeWithCoder:(NSCoder *)aCoder {
     //    [aCoder encodeObject:self.name forKey:@"Name"]; TODO: we should be able to remove this.
     //    [aCoder encodeBool:self.local forKey:@"Local"]; TODO: we should be able to remove this.
     //    NSLog(@"local == %d", self.local);
     [aCoder encodeObject:self.photoID forKey:@"photoID"];
     [aCoder encodeObject:self.photoTitle forKey:@"Title"];
     [aCoder encodeObject:self.photoNote forKey:@"Note"];
     [aCoder encodeObject:self.photoCreationDate forKey:@"CreationDate"];
     //[aCoder encodeObject:self.photoLocation forKey:@"Location"];
     [aCoder encodeBool:self.isAlbumPreview forKey:@"AlbumPreview"];
     [aCoder encodeBool:self.isFavoritePreview forKey:@"FavoritePreview"];
     [aCoder encodeBool:self.thumbnailNeedsRedraw forKey:@"ThumbnailNeedsRedraw"];
     [aCoder encodeBool:self.photoFavorited forKey:@"Favorited"]; //cjm favorites
     [aCoder encodeObject:self.originalAlbum forKey:@"OriginalAlbum"];
     }
 */
    
    required init?(coder aDecoder: NSCoder) {
        <#code#>
    }
/*
    - (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    if(self) {
    //        self.name = [aDecoder decodeObjectForKey:@"Name"];  TODO: we should be able to remove this.
    //        self.local = [aDecoder decodeBoolForKey:@"Local"];  TODO: we should be able to remove this.
    self.photoID = [aDecoder decodeObjectForKey:@"photoID"];
    self.photoTitle = [aDecoder decodeObjectForKey:@"Title"];
    self.photoNote = [aDecoder decodeObjectForKey:@"Note"];
    self.photoCreationDate = [aDecoder decodeObjectForKey:@"CreationDate"];
    //self.photoLocation = [aDecoder decodeObjectForKey:@"Location"];
    self.isAlbumPreview = [aDecoder decodeBoolForKey:@"AlbumPreview"];
    self.isFavoritePreview = [aDecoder decodeBoolForKey:@"FavoritePreview"];
    self.thumbnailNeedsRedraw = [aDecoder decodeBoolForKey:@"ThumbnailNeedsRedraw"];
    self.photoFavorited = [aDecoder decodeBoolForKey:@"Favorited"]; //cjm favorites
    self.selectCoverHidden = YES;
    self.originalAlbum = [aDecoder decodeObjectForKey:@"OriginalAlbum"];
    
    if (!self.isAlbumPreview)
    self.isAlbumPreview = NO;
    
    if (!self.isFavoritePreview)
    self.isFavoritePreview = NO;
    
    if (!self.photoFavorited)
    self.photoFavorited = NO;
    }
    return self;
    }
 */
}
