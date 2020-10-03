//
//  PHNAlbumsTableViewController.swift
//  Unroll2
//
//  Created by Curtis McCarthy on 6/28/19.
//  Copyright © 2019 Bluewraith. All rights reserved.
//

import UIKit
import Photos

class PHNAlbumsTableViewController: UITableViewController, PHNAlbumDetailViewControllerDelegate, PHNFullImageViewControllerDelegate, UIPopoverPresentationControllerDelegate, PHNPopoverDelegate, PHNPhotoGrabCompletionDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHNAlbumPickerDelegate {
    
    private let PHNAlbumsCellIdentifier = "AlbumCell"
    private let PHNAlbumPickerNavigationIdentifier = "AListPickerViewController"
    
    // Search bar
    let searchController = UISearchController(searchResultsController: nil)
    
    // Segue identifiers
    private let SEGUE_VIEW_GALLERY = "ViewGallery"
    private let SEGUE_EDIT_ALBUM = "EditAlbum"
    private let SEGUE_ADD_ALBUM = "AddAlbum"
    private let SEGUE_QUICK_NOTE = "ViewQuickNote"
    private let SEGUE_VIEW_SETTINGS = "ViewSettings"
    
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    private var popoverPresent = false
    var userColor: UIColor?
    var userColorTag: Int? // was NSNumber
    var selectedPhotos: [PhotoNote]?
    
    var imagePicker: UIImagePickerController?
    var flashButton: UIButton?
    var doneButton: UIButton?
    var capturedPhotos: UIImageView?
    var cameraCancelButton: UIButton?
    var cameraFlipButton: UIButton?
    var lastOrientation: UIDeviceOrientation?
    
    var pickerPhotos: [[String : Any?]]?
    var imageManager: PHCachingImageManager?

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register cell.
        let nib = UINib(nibName: "PHNAlbumListTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: PHNAlbumsCellIdentifier)
        tableView.rowHeight = 120 // was 80
        
        prepareSearchBar()
    }
    
    /// Sets up and adds the search bar to the scene.
    func prepareSearchBar() {
//        searchController.searchResultsUpdater = self
//        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Photo Notes"
        if #available(iOS 13.0, *) {
            searchController.searchBar.searchTextField.backgroundColor = .white
        } 
        definesPresentationContext = true
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
        } else {
            tableView.tableHeaderView = searchController.searchBar
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        appearanceForPreferredColor()
        navigationController?.toolbar.isHidden = false
        navigationController?.toolbar.isTranslucent = true
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.isTranslucent = true
        
        let backgroundView = UIImageView(image: UIImage(named: "AlbumListBackground"))
        backgroundView.contentMode = .scaleAspectFill
        tableView.backgroundView = backgroundView
        
        noAlbumsPopUp()
        tableView.reloadData()
    }
    
    /// Updates navigation bar style, tint, and color based on user selected theme color.
    func appearanceForPreferredColor() {
        let themeColor = PHNUser.current.preferredThemeColor
        userColor = themeColor.colorForTheme()
        
        let colorBrightness = themeColor.colorBrightness()
        switch colorBrightness {
        case .light:
            // Light theme will require dark text and icons.
            navigationController?.navigationBar.barStyle = .default
            navigationController?.navigationBar.tintColor = .black
            navigationController?.toolbar.tintColor = .black
            navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.black]
        case .dark:
            // Dark themes will require light text and icons.
            navigationController?.navigationBar.barStyle = .default
            navigationController?.navigationBar.tintColor = .white
            navigationController?.toolbar.tintColor = .white
            navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white]
        }
        
//        userColorTag = tag // cjm modernize - figure out what needs to be done with userColorTag
        navigationController?.navigationBar.barTintColor = userColor
        navigationController?.toolbar.barTintColor = userColor
    }
    
    //If there are no albums, prompt the user to create one after a delay.
    func noAlbumsPopUp() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            if PHNAlbumManager.sharedInstance.allAlbums.count == 0 {
                self?.navigationItem.prompt = "Tap + below to create a new Photo Notes album."
            } else {
                self?.navigationItem.prompt = nil
            }
        }
    }
    
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        if popoverPresent {
            dismiss(animated: true, completion: nil)
            popoverPresent = false
        }
    }
    
    // MARK: - TableView Data Source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return PHNAlbumManager.sharedInstance.allAlbums.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PHNAlbumsCellIdentifier, for: indexPath) as! PHNAlbumListTableViewCell
        let album = PHNAlbumManager.sharedInstance.allAlbums[indexPath.row]
        cell.configureWithTitle(album.albumTitle, count: album.albumPhotos.count)
        cell.configureThumbnail(forAlbum: album)
//        cell.accessoryType = .detailButton
        cell.showsReorderControl = true
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 1.0, height: 1.0))
        return view
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 4.0
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 1.0, height: 1.0))
        return view
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 4.0
    }
    
    //MARK: - TableView Delegate
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let popVC = PHNPopoverViewController()
        let album = PHNAlbumManager.sharedInstance.allAlbums[indexPath.row]
        popVC.name = album.albumTitle
        popVC.note = album.albumNote
        popVC.indexPath = indexPath
        popVC.delegate = self
        
        popVC.modalPresentationStyle = .popover
        let popController = popVC.popoverPresentationController
        popController?.delegate = self
        popController?.permittedArrowDirections = .any
        popController?.backgroundColor = UIColor(white: 0.0, alpha: 0.67)
        
        let cell = tableView.cellForRow(at: indexPath)!
        popController?.sourceView = cell
        popController?.sourceRect = CGRect(x: cell.bounds.size.width - 33.0, y: cell.bounds.size.height / 2.0, width: 1.0, height: 1.0)
        popoverPresent = true
        present(popVC, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "ViewGallery", sender: tableView.cellForRow(at: indexPath))
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //MARK: - Photo Fetch
    
    func getCenterMaxSquareImageByCroppingImage(_ image: UIImage, andShrinkToSize newSize: CGSize) -> UIImage {
        guard let imageCG = image.cgImage else { return UIImage(named: "NoImage")! }
        // Get crop bounds
        var centerSquareSize: CGSize = .zero
        let originalImageWidth = CGFloat(imageCG.width)
        let originalImageHeight = CGFloat(imageCG.height)
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
        
        // Crop and create CGImageRef. This is where future improvement likely lies.
        let cropRect = CGRect(x: x, y: y, width: centerSquareSize.width, height: centerSquareSize.height)
        let imageRef = imageCG.cropping(to: cropRect)! //CGImageCreateWithImageInRect(image.cgImage!, cropRect)
        let cropped = UIImage(cgImage: imageRef, scale: 0.0, orientation: image.imageOrientation)
        
        // Scale the image down to the smaller file size and return.
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        cropped.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    @IBAction func photoGrab() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        // Access camera
        let cameraAction = UIAlertAction(title: "Take Photo", style: .default, handler: { [weak self] action in
            self?.openCamera()
        })
        // Access photo library
        let libraryAction = UIAlertAction(title: "Choose From Library", style: .default, handler: { [weak self] action in
            self?.photosFromLibrary()
        })
        // Cancel
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(cameraAction)
        alert.addAction(libraryAction)
        alert.addAction(cancel)
        
        alert.popoverPresentationController?.barButtonItem = cameraButton
        alert.popoverPresentationController?.permittedArrowDirections = .down
        alert.popoverPresentationController?.sourceView = self.view
        
        present(alert, animated: true, completion: nil)
    }
    
    func photosFromLibrary() {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            if status != .authorized {
                let adjustPrivacyController = UIAlertController(title: "Denied access to Photos", message: "You will need to give Photo Notes permission to import from your Photo Library.\nPlease allow Photo Notes access to your Photo Library by going to Settings>Privacy>Photos", preferredStyle: .alert)
                let dismiss = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
                adjustPrivacyController.addAction(dismiss)
                
                self?.present(adjustPrivacyController, animated: true, completion: nil)
            } else {
                // requestAuthorization() is asynchronous. Must dispatch to main.
                DispatchQueue.main.async {
                    self?.presentPhotoGrabViewController()
                }
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
    
    //MARK: - Photo Grab Scene Delegate
    
    func photoGrabSceneDidCancel() {
        dismiss(animated: true, completion: nil)
    }
    
    func photoGrabSceneDidFinishSelectingPhotos(_ photos: [PHAsset]) {
        var newImages = [PhotoNote]()
        // Pull the images, image creation dates, and image locations from each PHAsset in the received array.
        let fileSerializer = PHNFileSerializer()
        
        if imageManager == nil {
            imageManager = PHCachingImageManager()
        }
        
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
                        
//                        imageLoadGroup.leave()
                    }
                    imageLoadGroup.leave()
                })
            })
            assetImage.photoCreationDate = asset.creationDate
            newImages.append(assetImage)
        }
        
        selectedPhotos = Array(newImages)
        
        imageLoadGroup.notify(queue: .main) { [weak self] in
            self?.navigationController?.view.isUserInteractionEnabled = true
            self?.dismiss(animated: true, completion: nil)
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let navVC = storyboard.instantiateViewController(withIdentifier: "AListPickerViewController") as! UINavigationController
            let aListPickerVC = navVC.topViewController as! PHNAlbumPickerViewController
            aListPickerVC.delegate = self
            aListPickerVC.title = "Select Destination"
            aListPickerVC.currentAlbumName = nil
            aListPickerVC.userColor = self?.userColor;
            aListPickerVC.userColorTag = self?.userColorTag;
            
            self?.present(aListPickerVC, animated: true, completion: nil)
        }
    }
    
    func albumPickerViewControllerDidCancel(_ controller: PHNAlbumPickerViewController) {
        selectedPhotos = nil
        dismiss(animated: true, completion: nil)
    }
    
    func albumPickerViewController(_ controller: PHNAlbumPickerViewController, didFinishPicking album: PHNPhotoAlbum) {
        guard selectedPhotos != nil, !selectedPhotos!.isEmpty else {
            dismiss(animated: true, completion: nil)
            return
        }
        
        for image in selectedPhotos! {
            image.selectCoverHidden = true
            image.photoTitle = "No Title Created "
            image.photoNote = "Tap Edit to change the title and note!"
            image.photoFavorited = false
            image.originalAlbum = album.albumTitle
        }
        album.addMultiple(selectedPhotos!)
        PHNAlbumManager.sharedInstance.save()
        
        selectedPhotos = nil
        flashButton = nil
        capturedPhotos = nil
        cameraCancelButton = nil
        cameraFlipButton = nil
        doneButton = nil
        imagePicker = nil
        pickerPhotos = nil
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: - ImagePicker Delegate and Controls
    
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
    
    @objc func updateFlashMode() {
        if let flashMode = imagePicker?.cameraFlashMode, flashMode == .off {
            imagePicker?.cameraFlashMode = .on
            flashButton?.setImage(UIImage(named: "FlashOn"), for: .normal)
        } else {
            imagePicker?.cameraFlashMode = .off
            flashButton?.setImage(UIImage(named: "FlashOff"), for: .normal)
        }
    }
    
    @objc func reverseCamera() {
        if let camDevice = imagePicker?.cameraDevice, camDevice == .rear {
            imagePicker?.cameraDevice = .front
        } else {
            imagePicker?.cameraDevice = .rear
        }
    }
    
    @objc func shutterPressed() {
        imagePicker?.takePicture()
    }
    
    @objc func photoCaptureFinished() {
        guard let pickedPhotos = pickerPhotos else {
            navigationController?.view.isUserInteractionEnabled = true
            dismiss(animated: true, completion: nil)
            return
        }
        
        let fileSerializer = PHNFileSerializer()
        var tempAlbum = [PhotoNote]()
        
        for dic in pickedPhotos {
            let newPhotoNote = PhotoNote()
            if let newPhotoData = dic["newImage"] as? NSData {
                fileSerializer.writeObject(newPhotoData, toRelativePath: newPhotoNote.fileName)
            }
            if let thumbnail = dic["newThumbnail"] as? UIImage {
                fileSerializer.writeImage(thumbnail, toRelativePath: newPhotoNote.thumbnailFileName)
            }
            
            newPhotoNote.photoCreationDate = Date()
            newPhotoNote.thumbnailNeedsRedraw = false
            tempAlbum.append(newPhotoNote)
        }
        
        selectedPhotos = Array(tempAlbum)
        navigationController?.view.isUserInteractionEnabled = true
        dismiss(animated: true, completion: nil)
        
        // Instantiate and present PHNAlbumPickerViewController
//        let albumPickerVC = PHNAlbumPickerViewController(nibName: "PHNAlbumPickerViewController", bundle: nil)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navVC = storyboard.instantiateViewController(withIdentifier: PHNAlbumPickerNavigationIdentifier) as! UINavigationController
        let albumPickerVC = navVC.topViewController as! PHNAlbumPickerViewController
        albumPickerVC.delegate = self
        albumPickerVC.title = "Select Destination"
        albumPickerVC.currentAlbumName = nil
        albumPickerVC.userColor = userColor
        albumPickerVC.userColorTag = userColorTag
        present(navVC, animated: true, completion: nil)
        
        PHNAlbumManager.sharedInstance.save()
    }
    
    @objc func cancelCamera() {
        dismiss(animated: true) { [weak self] in
            self?.pickerPhotos = nil
            self?.imagePicker = nil
        }
    }
    
    //MARK: - List Editing
    
    @IBAction func editTableView() {
        if editButton.title == "Edit" {
            editButton.title = "Done"
            tableView.setEditing(false, animated: true)
        } else {
            editButton.title = "Edit"
            tableView.setEditing(true, animated: true)
            
            PHNAlbumManager.sharedInstance.save()
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let album = PHNAlbumManager.sharedInstance.allAlbums[indexPath.row]
        if album.albumTitle == "Favorites" {
            let alert = UIAlertController(title: "Cannot delete the Favorites album.", message: "The Favorites album is removed automatically when there are 0 favorited photo notes.", preferredStyle: .alert)
            let actionDismiss = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alert.addAction(actionDismiss)
            present(alert, animated: true, completion: nil)
        } else {
            let message = "Any photo notes in \(album.albumTitle) will be permanently deleted."
            let alert = UIAlertController(title: "Delete Album?", message: message, preferredStyle: .alert)
            
            // TODO double check logic here.
            let actionDelete = UIAlertAction(title: "Delete", style: .destructive) { [weak self] (action) in
                if let favAlbum = PHNAlbumManager.sharedInstance.favPhotosAlbum,
                    let favInt = PHNAlbumManager.sharedInstance.allAlbums.firstIndex(of: favAlbum) {
                    let favPath = IndexPath(row: favInt, section: 0)
                    let favoriteActive = (favAlbum.albumPhotos.count > 0) ? true : false
                    PHNAlbumManager.sharedInstance.removeAlbumAtIndex(indexPath.row)
                    PHNAlbumManager.sharedInstance.save()
                    if favAlbum.albumPhotos.count < 1 && favoriteActive {
                        tableView.deleteRows(at: [indexPath, favPath], with: .fade)
                    } else {
                        tableView.deleteRows(at: [indexPath], with: .fade)
                    }
                    tableView.reloadData()
                    self?.noAlbumsPopUp()
                }
            }
            
            let actionCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alert.addAction(actionDelete)
            alert.addAction(actionCancel)
            present(alert, animated: true, completion: nil)
        }
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        PHNAlbumManager.sharedInstance.replaceAlbumAtIndex(destinationIndexPath.row,
                                         withAlbumAtIndex: sourceIndexPath.row)
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else { return }
        
        switch identifier {
        case SEGUE_VIEW_GALLERY:
            let indexPath = tableView.indexPath(for: sender as! UITableViewCell)
            let sentAlbum = PHNAlbumManager.sharedInstance.allAlbums[indexPath!.row]
            sentAlbum.delegate = PHNAlbumManager.sharedInstance
            let galleryVC = segue.destination as! PHNGalleryViewController
            galleryVC.album = sentAlbum
            galleryVC.userColor = userColor
            galleryVC.userColorTag = userColorTag
        case SEGUE_EDIT_ALBUM:
            let indexPath = tableView.indexPath(for: sender as! UITableViewCell)
            let sentAlbum = PHNAlbumManager.sharedInstance.allAlbums[indexPath!.row]
            let navVC = segue.destination as! UINavigationController
            let detailVC = navVC.viewControllers[0] as! PHNAlbumDetailViewController
            detailVC.albumToEdit = sentAlbum
            detailVC.title = "Album Info"
            detailVC.delegate = self
            detailVC.userColor = userColor
            detailVC.userColorTag = userColorTag
        case SEGUE_ADD_ALBUM:
            let navVC = segue.destination as! UINavigationController
            let detailVC = navVC.viewControllers[0] as! PHNAlbumDetailViewController
            detailVC.delegate = self
            detailVC.title = "Create Album"
            detailVC.userColor = userColor
            detailVC.userColorTag = userColorTag
        case SEGUE_QUICK_NOTE:
            let album = PHNAlbumManager.sharedInstance.userQuickNote
            let navVC = segue.destination as! UINavigationController
            let vc = navVC.viewControllers[0] as! PHNFullImageViewController
            vc.delegate = self
            vc.index = 0
            vc.albumName = album.albumTitle
            vc.isQuickNote = true
            vc.userColor = userColor
            vc.userColorTag = userColorTag
            vc.barsVisible = true
            let numOpac = UserDefaults.standard.value(forKey: "noteOpacity") as? NSNumber
            vc.noteOpacity = (numOpac != nil) ? CGFloat(exactly: numOpac!) : 0.75
        case SEGUE_VIEW_SETTINGS:
            let navVC = segue.destination as! UINavigationController
            navVC.modalPresentationStyle = .fullScreen
//            let vc = navVC.viewControllers[0] as! PHNSettingsViewController
        default:
            print("PHNAlbumsTableViewController performing segue with identifier: \(identifier)")
        }
    }
    
    //MARK: - DetailViewController Delegate
    
    func albumDetailViewControllerDidCancel(_ controller: PHNAlbumDetailViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    func albumDetailViewController(_ controller: PHNAlbumDetailViewController, didFinishAddingAlbum album: PHNPhotoAlbum) {
        let newRowIndex = PHNAlbumManager.sharedInstance.allAlbums.count
        
        PHNAlbumManager.sharedInstance.addAlbum(album)
        
        let indexPath = IndexPath(row: newRowIndex, section: 0)
        let indexPaths = [indexPath]
        tableView.insertRows(at: indexPaths, with: .automatic)
        
        PHNAlbumManager.sharedInstance.save()
        
        dismiss(animated: true, completion: nil)
    }
    
    func albumDetailViewController(_ controller: PHNAlbumDetailViewController, didFinishEditingAlbum album: PHNPhotoAlbum) {
        tableView.reloadData()
        PHNAlbumManager.sharedInstance.save()
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: - Popover Delegate
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        popoverPresent = false
    }
    
    func editTappedForIndexPath(_ indexPath: IndexPath) {
        dismiss(animated: true, completion: nil)
        performSegue(withIdentifier: SEGUE_EDIT_ALBUM, sender: tableView.cellForRow(at: indexPath))
    }
    
}
