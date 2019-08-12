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

class PHNGalleryViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, PHNPhotoGrabCompletionDelegate, PHNAlbumPickerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var album: PHNPhotoAlbum! {
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
    var pickerPhotos: [[String : Any?]]?
    
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
            
            var tempFullImage: UIImage?
            PHNServices.sharedInstance.fetchImage(photoNote: imageForCell) { (fetchedImage) in
                tempFullImage = fetchedImage
            }
            let thumbnail = getCenterMaxSquareImageByCroppingImage((tempFullImage ?? UIImage(named: "NoImage")!) , andShrinkToSize: cellSize)
            imageForCell.thumbnailNeedsRedraw = (tempFullImage == nil)
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
            exportButton.isEnabled = (album.albumTitle == "Favorites") ? false : true
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
    
    @IBAction func toggleEditMode() {
        if editButton.title == "Select" {
            editButton.title = "Cancel"
            editMode = true
            toggleEditControls()
            collectionView.allowsMultipleSelection = true
        } else if editButton.title == "Cancel" {
            editButton.title = "Select"
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
            if album.albumTitle != "Favorites" {
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
        PHPhotoLibrary.requestAuthorization { [weak self] (status) in
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
                self?.present(adjustPrivacyController, animated: true, completion: nil)
            } else {
                self?.presentPhotoGrabViewController()
            }
        }
    }
    
    /// Present users photo library.
    func presentPhotoGrabViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navigationVC = storyboard.instantiateViewController(withIdentifier: "NavPhotoGrabViewController") as! UINavigationController
        let vc = navigationVC.topViewController as! PHNImportAlbumsViewController
        vc.delegate = self
        vc.userColor = userColor
        vc.userColorTag = userColorTag
        vc.singleSelection = false
        
        present(navigationVC, animated: true, completion: nil)
    }
    
    // Mass delete options.
    @IBAction func deleteSelected() {
        guard let paths = collectionView.indexPathsForSelectedItems else {
            let alert = UIAlertController(title: "No Photos Selected", message: "You must select some photos to delete first.", preferredStyle: .alert)
            let dismiss = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alert.addAction(dismiss)
            present(alert, animated: true, completion: nil)
            return
        }
        selectedCells = paths
        
        let alertController = UIAlertController(title: "Delete Photos?", message: "You cannot recover these photo notes after deleting.", preferredStyle: .actionSheet)
        
        // IMPROVING AND ADDING LATER : functionality for mass export and delete on images.
        // TODO: Save selected photos to Photos app and then delete.
        // UIAlertAction *saveThenDeleteAction = [UIAlertAction actionWithTitle:@"Save to Photos app and then delete" style:UIAlertActionStyleDefault handler:^(UIAlertAction *actionToSaveThenDelete){ ...
        
        // Delete photos without saving to Photos app.
        let deleteAction = UIAlertAction(title: "Delete Photos Permanently", style: .destructive) { [unowned self] (_) in
            var doomedArray = [PhotoNote]()
            for itemPath in self.selectedCells! {
                let doomedImage = self.album.albumPhotos[itemPath.row]
                doomedArray.append(doomedImage)
            }
            PHNAlbumManager.sharedInstance.albumWithName(self.album.albumTitle, deleteImages: doomedArray)
            PHNAlbumManager.sharedInstance.checkFavoriteCount()
            PHNAlbumManager.sharedInstance.save()
            if self.album.albumPhotos.count < 1 {
                self.navigationController?.popViewController(animated: true)
            }
            self.collectionView.deleteItems(at: self.selectedCells!)
            self.toggleEditMode()
            self.confirmEditButtonEnabled()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: {
                self.collectionView.reloadData()
            })
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
//        alertController.addAction(saveThenDeleteAction)
        alertController.addAction(deleteAction)
        alertController.addAction(cancel)
        
        alertController.popoverPresentationController?.barButtonItem = deleteButton
        alertController.popoverPresentationController?.sourceView = view
        alertController.popoverPresentationController?.permittedArrowDirections = .down
        
        present(alertController, animated: true, completion: nil)
    }
    
    // Mass transfer options
    @IBAction func exportSelected() {
        guard let paths = collectionView.indexPathsForSelectedItems else {
            let alert = UIAlertController(title: "No Photos Selected", message: "You must select some photos to transfer first.", preferredStyle: .alert)
            let dismiss = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alert.addAction(dismiss)
            present(alert, animated: true, completion: nil)
            return
        }
        selectedCells = paths
        
        let alertController = UIAlertController(title: "Transfer", message: nil, preferredStyle: .actionSheet)
        
        // IMPROVING AND ADDING LATER : functionality for mass copy of selected photos
        //TODO: Copy selected photos to Camera Roll in the Photos app.
        
        // Copy the selected photos to another album within Photo Notes
        let alternateAlbumExport = UIAlertAction(title: "Photos And Notes To Alternate Album", style: .default) { [weak self] (_) in
            let storyboardName = "Main"
            let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
            let navVC = storyboard.instantiateViewController(withIdentifier: "AListPickerViewController") as! UINavigationController
            let albumPickerVC = navVC.topViewController as! PHNAlbumPickerViewController
            albumPickerVC.delegate = self
            albumPickerVC.title = "Select Destination"
            albumPickerVC.currentAlbumName = self?.album.albumTitle
            albumPickerVC.userColor = self?.userColor
            albumPickerVC.userColorTag = self?.userColorTag
            self?.present(navVC, animated: true, completion: nil)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
//        alertController.addAction(photosAppExport)
        alertController.addAction(alternateAlbumExport)
        alertController.addAction(cancel)
        alertController.popoverPresentationController?.barButtonItem = exportButton
        alertController.popoverPresentationController?.permittedArrowDirections = .down
        alertController.popoverPresentationController?.sourceView = view
        
        present(alertController, animated: true, completion: nil)
    }
    
    //MARK: - Image Picker Delegate and Controls
    
    func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            let alert = UIAlertController(title: "No Camera Available", message: "There's no camera available for Photo Notes to use.", preferredStyle: .alert)
            let dismiss = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alert.addAction(dismiss)
            present(alert, animated: true, completion: nil)
            
            return
        }
        
        let mediaType = AVMediaType.video
        let authStatus = AVCaptureDevice.authorizationStatus(for: mediaType)
        if authStatus != .authorized {
            AVCaptureDevice.requestAccess(for: .video) { [weak self] (granted) in
                if granted {
                    #if DEBUG
                    print("Permission for camera access granted")
                    #endif
                    self?.prepAndDisplayCamera()
                } else {
                    let alert = UIAlertController(title: "Camera Access Denied", message: "Please allow Photo Notes permission to use the camera.", preferredStyle: .alert)
                    
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString),
                        UIApplication.shared.canOpenURL(settingsUrl)
                    {
                        let actionSettings = UIAlertAction(title: "Open Settings",
                                                           style: .default,
                                                           handler: { (_) in
                                                            UIApplication.shared.open(settingsUrl) { (success) in
                                                                #if DEBUG
                                                                print("Settings opened: \(success)")
                                                                #endif
                                                            }
                        })
                        alert.addAction(actionSettings)
                    }
                    
                    let actionDismiss = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
                    alert.addAction(actionDismiss)
                    
                    self?.present(alert, animated: true, completion: nil)
                }
            }
        } else {
            prepAndDisplayCamera()
        }
    }
    
    func prepAndDisplayCamera() {
        imagePicker = UIImagePickerController()
        imagePicker?.sourceType = UIImagePickerController.SourceType.camera
        imagePicker?.showsCameraControls = false
        imagePicker?.allowsEditing = false
        imagePicker?.delegate = self
        imagePicker?.cameraFlashMode = .off
        imagePicker?.cameraDevice = .rear
        
        // Determine if viewport needs translation, and find bottom bar height.
        let screenHeight = UIScreen.main.bounds.size.height
        let screenWidth = UIScreen.main.bounds.size.width
        var longDimension: CGFloat
        var shortDimension: CGFloat
        if screenHeight > screenWidth {
            longDimension = screenHeight
            shortDimension = screenWidth
        } else {
            longDimension = screenWidth
            shortDimension = screenHeight
        }
        var cameraFrame: CGSize
        let aspectRatio = CGFloat(4.0 / 3.0)
        cameraFrame = CGSize(width: shortDimension, height: shortDimension * aspectRatio)
        let portraitFrame = CGRect(x: 0, y: 0, width: shortDimension, height: longDimension)
        
        if longDimension > 800 {
            // Determine remaining space for bottom buttons.
            longDimension -= 44.0 // subtract top bar
            let adjustHeight = CGAffineTransform(translationX: 0.0, y: 44.0)
            imagePicker?.cameraViewTransform = adjustHeight
        }
        let bottomBarHeight = longDimension - cameraFrame.height // Subtract viewport.
        
        let overlay = cameraOverlayWithFrame(portraitFrame, containerHeight: bottomBarHeight)
        imagePicker?.cameraOverlayView = overlay
        imagePicker?.modalTransitionStyle = .coverVertical
        
        lastOrientation = UIDevice.current.orientation
        NotificationCenter.default.addObserver(self, selector: #selector(rotateCameraViews), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        present(imagePicker!, animated: true) { [weak self] in
            self?.rotateCameraViews()
        }
    }
    
    @objc func rotateCameraViews() {
        let orientation = UIDevice.current.orientation
        var rotation: Double = 1
        switch orientation {
        case .portrait:
            rotation = 0
        case .landscapeLeft:
            rotation = Double.pi / 2
        case .landscapeRight:
            rotation = -(Double.pi / 2)
        default:
            break
        }
        if rotation != 1 {
            UIView.animate(withDuration: 0.2) { [weak self] in
                let transform = CGAffineTransform(rotationAngle: CGFloat(rotation))
                self?.capturedPhotos?.transform = transform
                self?.flashButton?.transform = transform
                self?.cameraFlipButton?.transform = transform
                self?.doneButton?.transform = transform
                self?.cameraCancelButton?.transform = transform
            }
        }
        lastOrientation = orientation
    }
    
    // TODO replace with nib based overlay view?
    func cameraOverlayWithFrame(_ overlayFrame: CGRect, containerHeight barHeight: CGFloat) -> UIView {
        let mainOverlay = UIView(frame: overlayFrame)
        
        // Create container view for buttons.
        let buttonBar = UIView()
        buttonBar.backgroundColor = .clear
        buttonBar.clipsToBounds = true
        buttonBar.translatesAutoresizingMaskIntoConstraints = false
        mainOverlay.addSubview(buttonBar)
        buttonBar.centerXAnchor.constraint(equalTo: mainOverlay.centerXAnchor).isActive = true
        buttonBar.bottomAnchor.constraint(equalTo: mainOverlay.bottomAnchor).isActive = true
        buttonBar.widthAnchor.constraint(equalTo: mainOverlay.widthAnchor).isActive = true
        buttonBar.heightAnchor.constraint(equalToConstant: barHeight).isActive = true
        let saGuide = buttonBar.safeAreaLayoutGuide
        
        // Add container view to hold the top row of buttons.
        let topRow = UIView()
        topRow.backgroundColor = .clear
        topRow.translatesAutoresizingMaskIntoConstraints = false
        mainOverlay.addSubview(topRow)
        topRow.centerXAnchor.constraint(equalTo: saGuide.centerXAnchor).isActive = true
        topRow.leadingAnchor.constraint(equalTo: saGuide.leadingAnchor).isActive = true
        topRow.topAnchor.constraint(equalTo: saGuide.topAnchor).isActive = true
        topRow.trailingAnchor.constraint(equalTo: saGuide.trailingAnchor).isActive = true
        topRow.bottomAnchor.constraint(equalTo: saGuide.centerYAnchor).isActive = true
        let topGuide = topRow.safeAreaLayoutGuide
        
        // Add captured photos thumbnail
        capturedPhotos = UIImageView()
        capturedPhotos!.layer.borderColor = UIColor.lightGray.cgColor
        capturedPhotos!.layer.borderWidth = 1.0
        capturedPhotos!.layer.cornerRadius = 5.0
        capturedPhotos!.translatesAutoresizingMaskIntoConstraints = false
        capturedPhotos!.contentMode = .scaleAspectFit
        capturedPhotos!.image = UIImage(named: "NoImage")
        topRow.addSubview(capturedPhotos!)
        capturedPhotos!.widthAnchor.constraint(equalTo: topGuide.heightAnchor, multiplier: 0.7).isActive = true
        capturedPhotos!.heightAnchor.constraint(equalTo: topGuide.heightAnchor, multiplier: 0.7).isActive = true
        capturedPhotos!.centerXAnchor.constraint(equalTo: topGuide.centerXAnchor).isActive = true
        //        capturedPhotos!.topAnchor.constraint(equalTo: saGuide.topAnchor, constant: 16.0).isActive = true
        capturedPhotos!.centerYAnchor.constraint(equalTo: topGuide.centerYAnchor).isActive = true
        
        // Add flash button
        var currentFlash: UIImage
        if imagePicker!.cameraFlashMode == .on {
            currentFlash = UIImage(named: "FlashOn")!
        } else {
            currentFlash = UIImage(named: "FlashOff")!
        }
        flashButton =  UIButton(type: .custom)
        flashButton!.addTarget(self, action: #selector(updateFlashMode), for: .touchUpInside)
        flashButton!.setImage(currentFlash, for: .normal)
        flashButton!.tintColor = .white
        flashButton!.translatesAutoresizingMaskIntoConstraints = false
        topRow.addSubview(flashButton!)
        flashButton!.topAnchor.constraint(equalTo: topGuide.topAnchor, constant: 8.0).isActive = true
        //        flashButton!.centerYAnchor.constraint(equalTo: topGuide.centerYAnchor).isActive = true
        flashButton!.leadingAnchor.constraint(equalTo: topGuide.leadingAnchor, constant: 8.0).isActive = true
        flashButton!.heightAnchor.constraint(equalToConstant: 44.0).isActive = true
        flashButton!.widthAnchor.constraint(equalToConstant: 44.0).isActive = true
        
        // Add button for front/back camera toggle.
        cameraFlipButton = UIButton(type: .custom)
        cameraFlipButton!.setImage(UIImage(named: "CamFlip"), for: .normal)
        cameraFlipButton!.addTarget(self, action: #selector(reverseCamera), for: .touchUpInside)
        cameraFlipButton!.tintColor = .white
        cameraFlipButton!.translatesAutoresizingMaskIntoConstraints = false
        topRow.addSubview(cameraFlipButton!)
        cameraFlipButton!.topAnchor.constraint(equalTo: saGuide.topAnchor, constant: 8.0).isActive = true
        //        cameraFlipButton!.centerYAnchor.constraint(equalTo: topGuide.centerYAnchor).isActive = true
        cameraFlipButton!.trailingAnchor.constraint(equalTo: topGuide.trailingAnchor, constant: -8.0).isActive = true
        cameraFlipButton!.heightAnchor.constraint(equalToConstant: 44.0).isActive = true
        cameraFlipButton!.widthAnchor.constraint(equalToConstant: 44.0).isActive = true
        
        // Add container view to hold the bottom row of buttons.
        let bottomRow = UIView()
        bottomRow.backgroundColor = .clear
        bottomRow.translatesAutoresizingMaskIntoConstraints = false
        mainOverlay.addSubview(bottomRow)
        bottomRow.centerXAnchor.constraint(equalTo: saGuide.centerXAnchor).isActive = true
        bottomRow.leadingAnchor.constraint(equalTo: saGuide.leadingAnchor).isActive = true
        bottomRow.topAnchor.constraint(equalTo: saGuide.centerYAnchor).isActive = true
        bottomRow.trailingAnchor.constraint(equalTo: saGuide.trailingAnchor).isActive = true
        bottomRow.bottomAnchor.constraint(equalTo: saGuide.bottomAnchor).isActive = true
        let bottomGuide = bottomRow.safeAreaLayoutGuide
        
        // Add camera shutter button.
        let cameraButton = UIButton(type: .roundedRect)
        cameraButton.setImage(UIImage(named: "CameraShutter"), for: .normal)
        cameraButton.setImage(UIImage(named: "PressedCameraShutter"), for: .highlighted) // TODO: not triggering
        cameraButton.tintColor = .white
        cameraButton.addTarget(self, action: #selector(shutterPressed), for: .touchUpInside)
        cameraButton.translatesAutoresizingMaskIntoConstraints = false
        bottomRow.addSubview(cameraButton)
        cameraButton.centerXAnchor.constraint(equalTo: bottomGuide.centerXAnchor).isActive = true
        cameraButton.centerYAnchor.constraint(equalTo: bottomGuide.centerYAnchor).isActive = true
        
        // Add done button.
        doneButton = UIButton(type: .custom)
        doneButton!.setTitle("Done", for: .normal)
        doneButton!.setTitleColor(.darkGray, for: .normal)
        doneButton!.addTarget(self, action: #selector(photoCaptureFinished), for: .touchUpInside)
        doneButton!.translatesAutoresizingMaskIntoConstraints = false
        bottomRow.addSubview(doneButton!)
        doneButton!.isEnabled = false
        doneButton!.bottomAnchor.constraint(equalTo: bottomGuide.bottomAnchor, constant: -8.0).isActive = true
        //        doneButton!.bottomAnchor.constraint(equalTo: bottomGuide.centerYAnchor).isActive = true
        doneButton!.trailingAnchor.constraint(equalTo: bottomGuide.trailingAnchor, constant: -8.0).isActive = true
        
        // Add cancel button.
        cameraCancelButton = UIButton(type: .custom)
        cameraCancelButton!.setTitle("Cancel", for: .normal)
        cameraCancelButton!.translatesAutoresizingMaskIntoConstraints = false
        cameraCancelButton!.addTarget(self, action: #selector(cancelCamera), for: .touchUpInside)
        bottomRow.addSubview(cameraCancelButton!)
        cameraCancelButton!.bottomAnchor.constraint(equalTo: bottomGuide.bottomAnchor, constant: -8.0).isActive = true
        //        cameraCancelButton!.centerYAnchor.constraint(equalTo: bottomGuide.centerYAnchor).isActive = true
        cameraCancelButton!.leadingAnchor.constraint(equalTo: bottomGuide.leadingAnchor, constant: -8.0).isActive = true
        
        return mainOverlay
    }
    
    // Converting photo captured by in-app camera to PhotoNote.
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        doneButton?.isEnabled = true
        doneButton?.setTitleColor(.white, for: .normal)
        
        //        TODO: Use PHAsset instead of UIImage. cjm album fetch
        //        let newAsset = info[UIImagePickerController.InfoKey.phAsset]
        let newPhoto = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        //        let newPhotoData = newPhoto?.jpegData(compressionQuality: 1.0)
        let newPhotoData = newPhoto?.pngData()
        let thumbnail = getCenterMaxSquareImageByCroppingImage(newPhoto!, andShrinkToSize: CGSize(width: 120.0, height: 120.0))
        
        //cjm album fetch
        let metaDic = info[UIImagePickerController.InfoKey.mediaMetadata]
        #if DEBUG
        print("metaDic == \(metaDic ?? "nil")")
        #endif
        
        let dic: [String : Any?] = [ "newImage" : newPhotoData,
                                     "newThumbnail" : thumbnail ]
        
        if pickerPhotos == nil {
            pickerPhotos = []
        }
        pickerPhotos?.append(dic)
    }
    
    @objc func photoCaptureFinished() {
        let serializer = PHNFileSerializer()
        
        guard pickerPhotos != nil else {
            // TODO some alert saying pickerPhotos is empty, followed by cleanup, and return.
            return
        }
        for dic in pickerPhotos! {
            let newPhotoData = dic["newImage"]! as! Data
            let thumbnail = dic["newThumbnail"]! as! UIImage
            let newPhotoNote = PhotoNote()
            
            serializer.writeObject(newPhotoData, toRelativePath: newPhotoNote.fileName)
            serializer.writeImage(thumbnail, toRelativePath: newPhotoNote.thumbnailFileName)
            
            newPhotoNote.setInitialValuesWithAlbum(album.albumTitle)
            newPhotoNote.photoCreationDate = Date()
            newPhotoNote.thumbnailNeedsRedraw = false
            album.add(newPhotoNote)
        }
        
        flashButton = nil
        capturedPhotos = nil
        cameraCancelButton = nil
        cameraFlipButton = nil
        doneButton = nil
        imagePicker = nil
        pickerPhotos = nil
        NotificationCenter.default.removeObserver( self,
                                             name: UIDevice.orientationDidChangeNotification,
                                           object: nil)
        dismiss(animated: true, completion: nil)
        PHNAlbumManager.sharedInstance.save()
    }
    
    @objc func shutterPressed() {
        #if DEBUG
        print("SHUTTER PRESSED")
        #endif
        imagePicker?.takePicture()
    }
    
    @objc func updateFlashMode() {
        if imagePicker?.cameraFlashMode == .off {
            imagePicker?.cameraFlashMode = .on
            flashButton?.setImage(UIImage(named: "FlashOn"), for: .normal)
        } else {
            imagePicker?.cameraFlashMode = .off
            flashButton?.setImage(UIImage(named: "FlashOff"), for: .normal)
        }
    }
    
    @objc func reverseCamera() {
        if imagePicker?.cameraDevice == .rear {
            imagePicker?.cameraDevice = .front
        } else {
            imagePicker?.cameraDevice = .rear
        }
    }
    
    @objc func cancelCamera() {
        pickerPhotos = nil
        imagePicker = nil
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: - New Photo Note Prep
    
    // Holy Grail of of thumbnail creation.  Well... Holy Dixie Cup may be more appropriate.
    /// Takes full UIImage and compresses to thumbnail with size ~100KB.
    func getCenterMaxSquareImageByCroppingImage(_ image: UIImage, andShrinkToSize newSize: CGSize) -> UIImage {
        guard let imageCG = image.cgImage else { return UIImage(named: "NoImage")! }
        // Get crop bounds
        var centerSquareSize = CGSize.zero
        let originalImageWidth = CGFloat(imageCG.width)
        let originalImageHeight = CGFloat(imageCG.height)
//        var originalImageHeight: Double = CGImageGetHeight(image.cgImage)
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
        let cropRect = CGRect(x: x, y: y, width: centerSquareSize.height, height: centerSquareSize.width)
        let imageRef = imageCG.cropping(to: cropRect)!
        let cropped = UIImage(cgImage: imageRef, scale: 0.0, orientation: image.imageOrientation)
        
        // Scale the image down to the smaller file size and return.
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        cropped.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    //MARK: - PHNPhotoGrabDelegate
    
    func photoGrabSceneDidCancel() {
        dismiss(animated: true, completion: nil)
    }
    
    /// Iterate through array of selected photos, convert them to CJMImages, and add to the current album.
    func photoGrabSceneDidFinishSelectingPhotos(_ photos: [PHAsset]) {
        var newImages = [PhotoNote]()
        let fileSerializer = PHNFileSerializer()
        if imageManager == nil { imageManager = PHCachingImageManager() }
        
        let imageLoadGroup = DispatchGroup()
        for asset in photos {
            let assetImage = PhotoNote()
            
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.version = .current
            
            imageLoadGroup.enter()
            autoreleasepool(invoking: {
                imageManager!.requestImageData(for: asset, options: options, resultHandler: { (imageData, dataUTI, orientation, info) in
                    if let cInfo = info,
                        let degraded = cInfo[PHImageResultIsDegradedKey] as? Bool,
                        !degraded {
                        fileSerializer.writeObject(imageData, toRelativePath: assetImage.fileName)
                        //                        imageLoadGroup.leave()
                    }
                    imageLoadGroup.leave()
                })
            })
            
            imageLoadGroup.enter()
            autoreleasepool(invoking: {
                imageManager!.requestImage(for: asset, targetSize: CGSize(width: 120.0, height: 120.0), contentMode: .aspectFill, options: options, resultHandler: { (result, info) in
                    if let cResult = result,
                        let cInfo = info,
                        let degraded = cInfo[PHImageResultIsDegradedKey] as? Bool,
                        !degraded {
                        fileSerializer.writeImage(cResult, toRelativePath: assetImage.thumbnailFileName)
                        assetImage.thumbnailNeedsRedraw = false
                        
                                                imageLoadGroup.leave()
                    }
//                    imageLoadGroup.leave()
                })
            })
            assetImage.setInitialValuesWithAlbum(album.albumTitle)
            assetImage.photoCreationDate = asset.creationDate
            
            newImages.append(assetImage)
        }
        
        album.addMultiple(newImages)
        
        imageLoadGroup.notify(queue: .main) { [weak self] in
            self?.navigationController?.view.isUserInteractionEnabled = true
            self?.collectionView.reloadData()
            self?.dismiss(animated: true, completion: nil)
            PHNAlbumManager.sharedInstance.save()
            self?.navigationController?.view.isUserInteractionEnabled = true // TODO why repeat call?
        }
    }
    
    //MAKR: - PHNAlbumPicker Delegate
    
    // Dismiss list of albums to transfer photos to and deselect previously selected photos.
    func albumPickerViewControllerDidCancel(_ controller: PHNAlbumPickerViewController) {
        dismiss(animated: true, completion: nil)
        toggleEditMode()
    }
    
    func albumPickerViewController(_ controller: PHNAlbumPickerViewController, didFinishPicking album: PHNPhotoAlbum) {
        guard selectedCells != nil else {
            //error message about no selections and return
            #if DEBUG
            print("selectedCells == nil")
            #endif
            return
        }
        var transferringImages = [PhotoNote]()
        
        for indexPath in selectedCells! {
            let imageToTranser = album.albumPhotos[indexPath.row]
            imageToTranser.selectCoverHidden = true
            if imageToTranser.isAlbumPreview == true {
                imageToTranser.isAlbumPreview = false
                album.albumPreviewImage = nil
            }
            transferringImages.append(imageToTranser)
        }
        
        album.addMultiple(transferringImages)
        
        var indexSet = IndexSet()
        for indexPath in selectedCells! {
            indexSet.insert(indexPath.row)
        }
        album.removeAtIndices(indexSet)
        
        if album.albumPreviewImage == nil && album.albumPhotos.count > 0 {
            PHNAlbumManager.sharedInstance.albumWithName(album.albumTitle, createPreviewFromImage: album.albumPhotos[0])
        }
        
        PHNAlbumManager.sharedInstance.save()
        if album.albumPhotos.count < 1 {
            navigationController?.popViewController(animated: true)
        }
        collectionView.deleteItems(at: selectedCells!)
        toggleEditMode()
        collectionView.reloadData()
        dismiss(animated: true, completion: nil)
        confirmEditButtonEnabled()
        
        // Present and dismiss HUD, confirming action complete.
        let hudView = PHNHudView.hud(inView: navigationController!.view, withType: "Success", animated: true)
        hudView.text = "Done!"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: { [weak self] in
            hudView.removeFromSuperview()
            self?.collectionView.reloadData()
            self?.navigationController?.view.isUserInteractionEnabled = true
        })
    }
    
    //MARK: - CollectionViewFlowLayout Delegate
    
    // Establishes cell size based on device screen size.  4 cells across in portrait, 5 cells across in landscape.
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if newCellSize == 0.0 {
            let cvSize = collectionView.safeAreaLayoutGuide.layoutFrame.size.width
            photoCellForWidth(cvSize)
        }
        return CGSize(width: newCellSize!, height: newCellSize!)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
    }
    
    // Resizes collectionView cells per sizeForItemAtIndexPath when user rotates device.
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        super.willRotate(to: toInterfaceOrientation, duration: duration)
        collectionView.collectionViewLayout.invalidateLayout()
    }
}
