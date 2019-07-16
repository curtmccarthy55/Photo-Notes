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
    var album: PHNPhotoAlbum {
        didSet { navigationItem.title = album.albumTitle }
    }
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
            let vc = segue.destination as! PHNPageImageViewController
            vc.albumName = album.albumTitle
            vc.albumCount = album.albumPhotos.count
            vc.initialIndex = indexPath!.item
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if editMode {
            return false
        }
        return true
    }
    
    //MARK: - NavBar Items
    
    @IBAction func toggleEditAction() {
        if editButton.title == "Select" {
            editButton.title = "Cancel"
            editMode = true
            toggleEditControls()
            collectionView.allowsMultipleSelection = true
        } else if editButton.title == "Cancel" {
            editMode.title = "Select"
            editMode = false
            clearCellSelections()
            toggleEditControls()
            selectedCells = nil
            collectionView.allowsMultipleSelection = false
        }
    }
    
    /// Change NavigationBar buttons based on current edit status.
    func toggleEditControls() {
        if editMode {
            cameraButton.isEnabled = false
            deleteButton.title = "Delete"
            deleteButton.isEnabled = false
            exportButton.title = "Transfer"
            exportButton.isEnabled = false
        } else {
            if album.albumTitle != "Favorites" { cameraButton.isEnabled = true }
            deleteButton.title = nil
            deleteButton.isEnabled = false
            exportButton.title = nil
            exportButton.isEnabled = false
        }
    }
    
    func confirmEditButtonEnabled() {
        if album.albumPhotos.count == 0 {
            editButton.isEnabled = false
            if album.albumPhotos != "Favorites" {
                let noPhotosAlert = UIAlertController(title: "No Photos Added Yet",
                                                      message: "Tap the camera button below to add photos",
                                                      preferredStyle: .alert)
                let actionCamera = UIAlertAction(title: "Take Picture", style: .default) { [weak self] (_) in
                    self?.openCamera()
                }
                let actionFetch = UIAlertAction(title: "Choose From Library", style: .default) { [weak self] (_) in
                    self?.photosFromLibrary()
                }
                let actionDismiss = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
                
                noPhotosAlert.addAction(actionCamera)
                noPhotosAlert.addAction(actionFetch)
                noPhotosAlert.addAction(actionDismiss)
                present(noPhotosAlert, animated: true, completion: nil)
            }
        } else {
            editButton.isEnabled = true
        }
    }
    
    /// Acquire photo library permission and provide paths to user camera and photo library for photo import.
    @IBAction func photoGrab() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // Access camera
        let actionCamera = UIAlertAction(title: "Take Photo", style: .default) { [weak self] (_) in
            self?.openCamera()
        }
        
        // Access photo library
        let actionFetch = UIAlertAction(title: "Choose From Library", style: .default) { [weak self] (_) in
            self?.photosFromLibrary()
        }
        
        let actionCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(actionCamera)
        alertController.addAction(actionFetch)
        alertController.addAction(actionCancel)
        
        alertController.popoverPresentationController?.barButtonItem = cameraButton
        alertController.popoverPresentationController?.permittedArrowDirections = .down
        alertController.popoverPresentationController?.sourceView = view
        
        present(alertController, animated: true, completion: nil)
    }
    
    func photosFromLibrary() {
        PHPhotoLibrary.requestAuthorization { (status) in
            if status != .authorized {
                let adjustPrivacyController = UIAlertController(title: "Denied Access to Photos", message: "Please allow Photo Notes permission to use the camera.", preferredStyle: .alert)
                
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString),
                    UIApplication.shared.canOpenURL(settingsUrl)
                {
                    let actionSettings = UIAlertAction(title: "Open Settings", style: .default, handler: { (_) in
                        UIApplication.shared.open(settingsUrl) { (success) in
                            #if DEBUG
                            print("Settings opened: \(success)")
                            #endif
                        }
                    })
                    adjustPrivacyController.addAction(actionSettings)
                }
                
                let actionDismiss = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
                
                adjustPrivacyController.addAction(actionDismiss)
                present(adjustPrivacyController, animated: true, completion: nil)
            } else {
                presentPhotoGrabViewController()
            }
        }
    }
    
    /// Present users photo library.
    func presentPhotoGrabViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navigationVC = storyboard.instantiateViewController(withIdentifier: "NavPhotoGrabViewController") as! UINavigationController
        let vc = navigationVC.topViewController as! PHNImportAlbumsVC
        vc.delegate = self
        vc.userColor = userColor
        vc.userColorTag = userColorTag
        vc.singleSelection = false
        
        present(navigationVC, animated: true, completion: nil)
    }
    
    @IBAction func deleteSelected() {
        guard selectedCells = Array(collectionView.indexPathsForSelectedItems) else {
            let alert = UIAlertController(title: "No Photos Selected", message: "You must select some photos to delete first", preferredStyle: .alert)
            let dismiss = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alert.addAction(dismiss)
            present(alert, animated: true, completion: nil)
            return
        }
        
        let alertController = UIAlertController(title: "Delete Photos?", message: "You cannot recover these photo notes after deleting.", preferredStyle: .actionSheet)
        
        // IMPROVING AND ADDING LATER : functionality for mass export and delete on images.
        // TODO: Save selected photos to Photos app and then delete.
        // UIAlertAction *saveThenDeleteAction = [UIAlertAction actionWithTitle:@"Save to Photos app and then delete" style:UIAlertActionStyleDefault handler:^(UIAlertAction *actionToSaveThenDelete){ ...
        
        // Delete photos without saving to Photos app.
        let deleteAction = UIAlertAction(title: "Delete Photos Permanently", style: .destructive) { [unowned self] (_) in
            var doomedArray = [PhotoNote]()
            for itemPath in selectedCells {
                let doomedImage = album.albumPhotos[itemPath.row]
                doomedArray.append(doomedImage)
            }
            PHNAlbumManager.sharedInstance.albumWithName(self.album.albumTitle, deleteImages: doomedArray)
            
        }
    }
    
    /*
/Mass delete options
- (IBAction)deleteSelcted:(id)sender {
    //Delete photos without saving to Photos app
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:@"Delete Photos Permanently" style:UIAlertActionStyleDefault handler:^(UIAlertAction *actionToDeletePermanently) {
            NSMutableArray *doomedArray = [NSMutableArray new];
            for (NSIndexPath *itemPath in self.selectedCells) {
                CJMImage *doomedImage = [self.album.albumPhotos objectAtIndex:itemPath.row];
                [doomedArray addObject:doomedImage];
            }
            [[CJMAlbumManager sharedInstance] albumWithName:self.album.albumTitle
            deleteImages:doomedArray];
            [[CJMAlbumManager sharedInstance] checkFavoriteCount];
            [[CJMAlbumManager sharedInstance] save];
            if (self.album.albumPhotos.count < 1) {
                [self.navigationController popViewControllerAnimated:YES];
            }
            [self.collectionView deleteItemsAtIndexPaths:self.selectedCells];
            [self toggleEditMode:self];
            [self confirmEditButtonEnabled];
            [self.collectionView performSelector:@selector(reloadData) withObject:nil afterDelay:0.4];
    }];


UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *cancelAction) {} ];

//    [alertController addAction:saveThenDeleteAction];
[alertController addAction:deleteAction];
[alertController addAction:cancel];

alertController.popoverPresentationController.barButtonItem = self.deleteButton;
alertController.popoverPresentationController.sourceView = self.view;
[alertController.popoverPresentationController setPermittedArrowDirections:UIPopoverArrowDirectionDown];

[self presentViewController:alertController animated:YES completion:nil];
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
