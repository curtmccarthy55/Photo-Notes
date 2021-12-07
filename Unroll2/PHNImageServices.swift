//
//  PHNImageServices.swift
//  Unroll2
//
//  Created by Curtis McCarthy on 12/6/21.
//  Copyright © 2021 Curtis McCarthy. All rights reserved.
//

import Foundation
import UIKit

/// Type for various image sizes that need to be loaded.  Raw value represents the minimum points for the shortest edge of an image (e.g. in a landscape photo, the shortest edge would be the vertical/y-axis edges).
enum ImageResolution: Float {
    case fullScreen     = 1.0 // TODO: change... Should be current display size.
    case smallThumbnail = 120.0
    case largeThumbnail = 195.0
    case server         = 1080.0
    case emailHigh      = 800.0 // 300.0
    case emailMedium    = 400.0 // 150.0
    case emailLow       = 300.0 // 100.0
    
    /// Increases the resolution factor by the provided scale (e.g. 1x, 2x, 3x).
    /// - Parameter factor: The factor to apply to the resolution, defaulting to the main screen's scale.
    func upscaleResolutionBy(_ factor: CGFloat = UIScreen.main.scale) -> CGFloat {
        let raw = CGFloat(rawValue)
        let scaledRes = factor * raw
        return scaledRes
    }
}

/// Handles image fetch (from user Photos, Dropbox, and other sources), image alteration (downsampling, thumbnail generation, etc), image caching, and image sending.
class PHNImageServices {
    /// `PHNImageServices` singleton.
    static let shared = PHNImageServices()
    private init() {}
    
    /// Creates a thumbnail image from the passed in `UIImage` (crops the center square of an image and scales its resolution).
    func generateSquareThumbnail(fromImage image: UIImage, size: ImageResolution = .largeThumbnail, scale: CGFloat = UIScreen.main.scale) -> UIImage {
        guard let imageCG = image.cgImage else { return UIImage(named: "NoImage")! }
        
        // Determine crop size.
        var centerSquareSize = CGSize()
        let originalWidth = image.cgImage!.width
        let originalHeight = image.cgImage!.height
        
        if originalHeight <= originalWidth {
            centerSquareSize.width = CGFloat(originalHeight)
            centerSquareSize.height = CGFloat(originalHeight)
        } else {
            centerSquareSize.width = CGFloat(originalWidth)
            centerSquareSize.height = CGFloat(originalWidth)
        }
        
        // Determine crop origin.
        let x = (CGFloat(originalWidth) - centerSquareSize.width) / 2.0
        let y = (CGFloat(originalHeight) - centerSquareSize.height) / 2.0
        
        // Crop and create CGImageRef. This is where future improvement likely lies.
        let cropRect = CGRect(x: x, y: y, width: centerSquareSize.width, height: centerSquareSize.height)
        let imageRef = imageCG.cropping(to: cropRect)! //CGImageCreateWithImageInRect(image.cgImage!, cropRect)
        let cropped = UIImage(cgImage: imageRef, scale: 0.0, orientation: image.imageOrientation)
        
        // Scale the image down to the smaller file size and return.
        let newSize = CGSize(width: CGFloat(size.rawValue), height: CGFloat(size.rawValue))
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        cropped.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
        
        /* Scope method end.
        // Crop and create CGImageRef.  Note: this is where future improvement likely lies.
        let cropRect = CGRect(x: x, y: y, width: centerSquareSize.width, height: centerSquareSize.height)
        let imageRef = image.cgImage!.cropping(to: cropRect)
        let cropped = UIImage(cgImage: imageRef!, scale: scale, orientation: image.imageOrientation)
        
        let newSize = CGSize(width: CGFloat(size.rawValue),
                            height: CGFloat(size.rawValue))
        let scaledDimension = size.upscaleResolutionBy(scale)
        let newSize = CGSize(width: scaledDimension,
                            height: scaledDimension)
        
        //return PDRFileSerializer.shared.downsampleImage(existingImage: cropped, to: newSize)!
        
        /* Using Image Renderer.
        //Scale the image down to the smaller file size and return
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { (context) in
            cropped.draw(in: CGRect(origin: .zero, size: newSize))
        }
 */
         */
    }
}
