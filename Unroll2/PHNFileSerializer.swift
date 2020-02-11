//
//  PHNFileSerializer.swift
//  Unroll2
//
//  Created by Curtis McCarthy on 7/2/19.
//  Copyright © 2019 Bluewraith. All rights reserved.
//

import UIKit

class PHNFileSerializer: NSObject {
    
    override init() {
        super.init()
        // TODO: PHASE OUT - model type transitions following Swift migration. Established post v2.1
        NSKeyedUnarchiver.setClass(PHNPhotoAlbum.self, forClassName: "CJMPhotoAlbum")
        NSKeyedUnarchiver.setClass(PhotoNote.self, forClassName: "CJMImage")
    }

    //MARK: - Read
    
    func readObjectFromRelativePath(_ path: String) -> Any? {
        let absolutePath = absolutePathFromRelativePath(path)
        var object: Any? = nil
        if FileManager.default.fileExists(atPath: absolutePath) {
            object = NSKeyedUnarchiver.unarchiveObject(withFile: absolutePath)
        }
        return object
    }
    
    /// Returns UIImage? read from a given file path on disk.
    func readImageFromRelativePath(_ path: String) -> UIImage? {
        if let data = readObjectFromRelativePath(path) {
            let imageData = UIImage(data: (data as! NSData) as Data) //TODO why all the casting?
            return imageData
        } else {
            return nil
        }
        
    }
    
    //MARK: - Write
    @discardableResult
    func writeObject(_ data: Any?, toRelativePath path: String) -> Bool {
        let filePath = absolutePathFromRelativePath(path)
        print("filePath == \(filePath)")
        return NSKeyedArchiver.archiveRootObject(data, toFile: filePath)
    }
    
    @discardableResult
    func writeImage(_ image: UIImage, toRelativePath path: String) -> Bool {
        // this method is just to maintain API balance with readImageFromRelativePath
        return writeObject(image, toRelativePath: path)
    }
    
    //MARK: - Delete
    
    func deleteImageWithFileName(_ fileName: String) {
        let fileManager = FileManager.default
        
        let filePath = absolutePathFromRelativePath(fileName)
        let thumbnailFilePath = filePath.appending("_sm")
        
        do {
            try fileManager.removeItem(atPath: filePath)
            print("Full image file deleted successfully!")
        }
        catch {
            print("Could not delete full image file: \(error.localizedDescription)")
        }
        
        do {
            try fileManager.removeItem(atPath: thumbnailFilePath)
            print("Thumbnail deleted successfully!")
        }
        catch {
            print("Could not delete thumbnail file: \(error.localizedDescription)")
        }
    }
    
    //MARK: - File Pathing
    
    func documentsDirectory() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths.first
        
        return documentsDirectory!
    }
    
    func absolutePathFromRelativePath(_ path: String) -> String {
        let directory = documentsDirectory() + "/"
        let absolutePath = directory.appending(path)
        
        return absolutePath
    }
}
