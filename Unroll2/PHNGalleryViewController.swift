//
//  PHNGalleryViewController.swift
//  Unroll2
//
//  Created by Curtis McCarthy on 7/11/19.
//  Copyright © 2019 Bluewraith. All rights reserved.
//

import UIKit
import Photos

private let reuseIdentifier = "GalleryCell"

private let SEGUE_VIEW_PHOTO = "ViewPhoto"

class PHNGalleryViewController: UICollectionViewController, PHNPhotoGrabCompletionDelegate, PHNAListPickerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var album: PHNPhotoAlbum
    var userColor: UIColor?
    var userColorTag: Int?
    
    var imageManager: PHCachingImageManager?
//    var fullImageVC: PHNPageImageViewController?
    var editMode = false
    
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var exportButton: UIBarButtonItem!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    var selectedCells: [IndexPath]?
    var pickerPhotos: [String : Any?]?
    
    var imagePicker: UIImagePickerController?
    var flashButton: UIButton?
    var capturedPhotos: UIImageView?
    var doneButton: UIButton?
    var cameraCancelButton: UIButton?
    var cameraFlipButton: UIButton?
    var lastOrientation: UIDeviceOrientation?
    
    var cellSize: CGSize {
        var columnSpaces: CGFloat
        if UIScreen.main.bounds.size.height > UIScreen.main.bounds.size.width {
            // Portrait
            columnSpaces = 3.0
        } else {
            // Landscape
            columnSpaces = 5.0
        }
        
        var sideLength: CGFloat
        sideLength = (view.bounds.size.width - view.safeAreaInsets.left - view.safeAreaInsets.right) / columnSpaces
        let returnSize = CGSize(width: sideLength, height: sideLength)
        return returnSize
    }
    var newCellSize: CGFloat?
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    //MARK: - Scene Set Up
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.isToolbarHidden = false
        navigationItem.title = album.albumTitle
        navigationItem.backBarButtonItem?.title = "Albums"
        
        let viewSize = view.bounds.size
        let contentOffset = CGPoint(x: 0, y: (viewSize.height * CGFloat(album.albumPhotos.count - 1)))
        collectionView?.setContentOffset(contentOffset, animated: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Make sure nav bars and associated controls are visible whenever the gallery appears.
        super.viewWillAppear(animated)
        
        editMode = false
        toggleEditControls()
        navigationController?.navigationBar.isHidden = false
        navigationController?.toolbar.isHidden = false
        navigationController?.navigationBar.prefersLargeTitles = true
        confirmEditButtonEnabled()
        
        newCellSize = 0.0
        collectionView?.reloadData()
        
        if album.albumTitle == "Favorites" {
            cameraButton.isEnabled = false
            if let favorites = PHNAlbumManager.sharedInstance.favPhotosAlbum, favorites.albumPhotos.count < 1 {
                navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func photoCellForWidth(_ saWidth: CGFloat) {
        var cellsPerRow: CGFloat = 0.0
//        CGFloat cellSpacing = 1.0
        
        if UIDevice.current.orientation.isLandscape {
            cellsPerRow = 6.0
        } else {
            cellsPerRow = 4.0
        }
        newCellSize = (saWidth - CGFloat(cellsPerRow + 1.0)) / cellsPerRow
        print("photoCellForWidth newCellSize == \(newCellSize ?? -1.0)")
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        print("viewWillTransitionToSize size.width == \(size.width), size.height == \(size.height)")
        super.viewWillTransition(to: size, with: coordinator)
        newCellSize = 0.0
        collectionViewLayout.invalidateLayout()
    }
    
    // Add photo count text to gallery footer.
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let footer = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "Footer", for: indexPath)
        
        let footerLabel = footer.viewWithTag(100) as! UILabel
        if album.albumPhotos.count > 1 {
            footerLabel.text = "\(album.albumPhotos.count) Photos"
        } else if album.albumPhotos.count == 1 {
            footerLabel.text = "1 Photo"
        } else {
            footerLabel.text = nil
        }
        
        return footer
    }
    
    // If any cells are selected when exiting the gallery, set their cellSelectCover property back to hidden.
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let selectedItems = collectionView.indexPathsForSelectedItems, selectedItems.count > 0 {
            for indexPath in selectedItems {
                let selectedItem = album.albumPhotos[indexPath.item]
                selectedItem.selectCoverHidden = true
            }
        }
    }
    
    //MARK: - CollectionView Data Source
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return album.albumPhotos.count
    }
    
    // Add thumbnail to image and, if it's currently selected for editing, reveal it's cellSelectCover.
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PHNPhotoCell
        let imageForCell = album.albumPhotos[indexPath.row]
        
        cell.updateWith(photoNote: imageForCell)
        
        if imageForCell.thumbnailNeedsRedraw {
            let fileSerializer = PHNFileSerializer()
            var tempFullImage = UIImage()
            PHNServices.sharedInstance.fetchImage(photoNote: imageForCell) { (fetchedImage) in
                tempFullImage = fetchedImage
            }
            let thumbnail = getCenterMaxSquareImageByCroppingImage(tempFullImage, andShrinkToSize: cellSize)
            imageForCell.thumbnailNeedsRedraw = false
            fileSerializer.writeImage(thumbnail, toRelativePath: imageForCell.thumbnailFileName)
            cell.updateWith(photoNote: imageForCell)
            PHNAlbumManager.sharedInstance.save()
        }
        
        cell.cellSelectCover.isHidden = imageForCell.selectCoverHidden
        
        return cell
    }
    
    //MARK: - CollectionView Delegate
    
    // If in editing mode, mark cell as selected and reveal cellCover and enable delete/transfer buttons.
    // Otherwise, segue to full image.
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if editMode {
            shouldPerformSegue(withIdentifier: SEGUE_VIEW_PHOTO, sender: nil)
            let selectedCell = collectionView.cellForItem(at: indexPath) as! PHNPhotoCell
            let selectedImage = album.albumPhotos[indexPath.row]
            selectedImage.selectCoverHidden = false
            selectedCell.cellSelectCover.isHidden = selectedImage.selectCoverHidden
            deleteButton.isEnabled = true
            exportButton.isEnabled = (album.albumPhotos == "Favorites") ? false : true
        } else {
            let selectedImage = album.albumPhotos[indexPath.item]
            selectedImage.selectCoverHidden = true
            shouldPerformSegue(withIdentifier: SEGUE_VIEW_PHOTO, sender: nil)
        }
    }
    
    // Hide cellSelectCover, and, if this was the last selected cell, disable the delete/transfer buttons.
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let deselectedCell = collectionView.cellForItem(at: indexPath) as! PHNPhotoCell
        let deselectedImage = album.albumPhotos[indexPath.row]
        deselectedImage.selectCoverHidden = true
        deselectedCell.cellSelectCover.isHidden = deselectedImage.selectCoverHidden
        
        if let selectedItems = collectionView.indexPathsForSelectedItems, selectedItems.count == 0 {
            deleteButton.isEnabled = false
            exportButton.isEnabled = false
        }
    }
    
    // For all currently selected cells, switch their selected status to NO and hide cellSelectCovers.
    func clearCellSelections() {
        guard let selectedItems = collectionView.indexPathsForSelectedItems else { return }
        
        for indexPath in selectedItems {
            collectionView.deselectItem(at: indexPath, animated: true)
            let cell = collectionView.cellForItem(at: indexPath) as! PHNPhotoCell
            let photoNote = album.albumPhotos[indexPath.row]
            photoNote.selectCoverHidden = true
            cell.cellSelectCover.isHidden = photoNote.selectCoverHidden
        }
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SEGUE_VIEW_PHOTO, let cell = sender as? PHNPhotoCell {
            let indexPath = collectionView.indexPath(for: cell)
            /* cjm migration incomplete
            let vc = segue.destination as! PHNPageImageViewController
            vc.albumName = album.albumTitle
            vc.albumCount = album.albumPhotos.count
            vc.initialIndex = indexPath!.item
 */
        }
    }
    /*
#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ViewPhoto"]) {
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:sender];
        CJMPageImageViewController *vc = (CJMPageImageViewController *)segue.destinationViewController;
        vc.albumName = self.album.albumTitle;
        vc.albumCount = self.album.albumPhotos.count;
        vc.initialIndex = indexPath.item;
    }
}
 */
    
    
    // Holy Grail of of thumbnail creation.  Well... Holy Dixie Cup may be more appropriate.
    /// Takes full UIImage and compresses to thumbnail with size ~100KB.
    func getCenterMaxSquareImageByCroppingImage(_ image: UIImage, andShrinkToSize newSize: CGSize) -> UIImage {
        // Get crop bounds
        var centerSquareSize: CGSize
        var originalImageWidth: Double = CGImageGetWidth(image.cgImage)
        var originalImageHeight: Double = CGImageGetHeight(image.cgImage)
        if originalImageHeight <= originalImageWidth {
            centerSquareSize.width = originalImageHeight
            centerSquareSize.height = originalImageHeight
        } else {
            centerSquareSize.width = originalImageWidth
            centerSquareSize.height = originalImageWidth
        }
        // Determine crop origin
        let x = (originalImageWidth - centerSquareSize.width) / 2.0
        let y = (originalImageHeight - centerSquareSize.height) / 2.0
        
        // Crop and create CGImageRef.  This is where an improvement likely lies
        var cropRect = CGRect(x: x, y: y, width: centerSquareSize.height, height: centerSquareSize.width)
        var imageRef = CGImageCreateWithImageInRect([image.cgImage], cropRect)
        let cropped = UIImage(cgImage: imageRef, scale: 0.0, orientation: image.imageOrientation)
        
        // Scale the image down to the smaller file size and return.
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        cropped.drawInRect(CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        CGImageRelease(imageRef)
        
        return newImage!
    }
    

}
