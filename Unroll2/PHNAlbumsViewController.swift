//
//  PHNAlbumsViewController.swift
//  Unroll2
//
//  Created by Curtis McCarthy on 12/3/21.
//  Copyright © 2021 Bluewraith. All rights reserved.
//

import Foundation
import UIKit
import Photos

/// Initial view controller, displaying the list of user Photo Notes albums, and offering navigation to Settings, QuickNote, etc.
class PHNAlbumsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchControllerDelegate {
    
    // Cell and Segue Identifiers
    private let PHNAlbumsCellIdentifier            = "AlbumCell"
    private let PHNAlbumPickerNavigationIdentifier = "AListPickerViewController"
    private let SEGUE_VIEW_GALLERY                 = "ViewGallery"
    private let SEGUE_EDIT_ALBUM                   = "EditAlbum"
    private let SEGUE_ADD_ALBUM                    = "AddAlbum"
    private let SEGUE_QUICK_NOTE                   = "ViewQuickNote"
    private let SEGUE_VIEW_SETTINGS                = "ViewSettings"
    
    // Outlets
    let searchController = UISearchController(searchResultsController: nil)
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    // ivars
    /// A temporary container for newly created Photo Notes, imported from a user library or captured by the camera.
    var newPhotoNotes: [PhotoNote]?
    /// Populated while camera in use.  May not need to hold onto this...
    var cameraController: PHNCameraController?
    // Likely removing popover UI
//    private var popoverPresent = false
    /// Caching image manager for loading user photo library collections.  TODO consider ways to get this out of here.  This primariy pertains to the data source for ImportAlbumsViewController and PhotoGrabViewController.  Consider moving logic to MediaImporter and passing that around?
    var imageManager: PHCachingImageManager?
    
    // MARK: - Scene set up
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerCells()
        prepareSearchBar()
        if #available(iOS 13, *) {
            view.backgroundColor = .systemGray5
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Adding the search bar after the view has appeared keeps it hidden until the user pulls down.
        // addSearchBar()
        
        noAlbumsPopUp()
    }
    
    /// Register custom cells for the table view.
    func registerCells() {
        // Register cell.
        let nib = UINib(nibName: "PHNAlbumListTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: PHNAlbumsCellIdentifier)
        tableView.rowHeight = 120 // was 80
    }
    
    /// Sets up the search controller.
    func prepareSearchBar() {
        searchController.delegate = self
//        searchController.searchResultsUpdater = self // requires conforming to UISearchResultsUpdating
        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = true
        searchController.searchBar.placeholder = NSLocalizedString("Search Photo Notes",
                                                          comment: "Search bar placeholder.")
        definesPresentationContext = true
        
//        searchController.searchBar.scopeButtonTitles = ["Titles", "Tags"]
    }
    
    /// Adds the search controller's search bar to the navigation bar.  Currently unused as the search controller itself is presented in `tappedSearch(_:)`
    func addSearchBar() {
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = true
        } else {
            tableView.tableHeaderView = searchController.searchBar
        }
    }
    
    /// If there are no albums, prompt the user to create one after a delay.
    func noAlbumsPopUp() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            if PHNAlbumManager.sharedInstance.allAlbums.count == 0 {
                self?.navigationItem.prompt = "Tap + below to create a new Photo Notes album."
            } else {
                self?.navigationItem.prompt = nil
            }
        }
    }
    
    // MARK: - BarButtonItem actions
    
    /// 'Magnifying glass' button action.  Presents the search controller.
    @IBAction func tappedSearch(_ sender: Any?) {
        present(searchController, animated: true, completion: nil)
    }
    
    /// 'Camera' button action.  Presents options to choose a photo from the library, take a new photo using the camera, or cancel.
    @IBAction func tappedCamera(_ sender: Any?) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        // Access camera
        let cameraAction = UIAlertAction(title: "Take Photo", style: .default, handler: { [unowned self] action in
            self.cameraController = PHNCameraController(presentingView: self)
            self.cameraController?.delegate = self
            self.cameraController?.openCamera()
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
    
    @IBAction func tappedEdit() {
        toggleEditMode()
    }
    
    // MARK: - Selectors and alert actions
    
    /// Confirm Photos library access authorization, then present.
    func photosFromLibrary() {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            if status == .authorized {
                // requestAuthorization() is asynchronous. Must dispatch to main.
                DispatchQueue.main.async {
                    self?.presentPhotoGrabViewController()
                }
            } else {
                let alertTitle = NSLocalizedString("Denied access to Photos",
                                          comment: "Denied access to Photos")
                let alertMessage = NSLocalizedString("You will need to give Photo Notes permission to import from your Photo Library.\nPlease allow Photo Notes access to your Photo Library by going to Settings>Privacy>Photos",
                                            comment: "")
                let adjustPrivacyController = UIAlertController(title: alertTitle,
                                                              message: alertMessage,
                                                       preferredStyle: .alert)
                let dismissCopy = NSLocalizedString("Dismiss", comment: "Dismiss")
                let actionDismiss = UIAlertAction(title: dismissCopy,
                                                  style: .cancel,
                                                handler: nil)
                adjustPrivacyController.addAction(actionDismiss)
                
                self?.present(adjustPrivacyController, animated: true, completion: nil)
            }
        }
    }
    
    /// Present users photo library.
    func presentPhotoGrabViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navigationVC = storyboard.instantiateViewController(withIdentifier: "NavPhotoGrabViewController") as! UINavigationController
        navigationVC.modalPresentationStyle = .fullScreen
        let vc = navigationVC.topViewController as! PHNImportAlbumsViewController
        vc.delegate = self
        vc.singleSelection = false
        
        present(navigationVC, animated: true, completion: nil)
    }
    
    
    // MARK: - Trait changes
    
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
//        if popoverPresent {
//            dismiss(animated: true, completion: nil)
//            popoverPresent = false
//        }
    }
    
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return PHNAlbumManager.sharedInstance.allAlbums.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PHNAlbumsCellIdentifier, for: indexPath) as! PHNAlbumListTableViewCell
        let album = PHNAlbumManager.sharedInstance.allAlbums[indexPath.row]
        cell.configureWithTitle(album.albumTitle, count: album.albumPhotos.count)
        cell.configureThumbnail(forAlbum: album)
//        cell.accessoryType = .detailButton
        cell.showsReorderControl = true
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
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
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        PHNAlbumManager.sharedInstance.replaceAlbumAtIndex(destinationIndexPath.row,
                                         withAlbumAtIndex: sourceIndexPath.row)
    }
    
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Navigate to the selected album's gallery.
        performSegue(withIdentifier: SEGUE_VIEW_GALLERY, sender: tableView.cellForRow(at: indexPath))
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //MARK: - List Editing
    
    /// Enable/disable table view editing, and change text of the edit button to indicate this state.
    func toggleEditMode() {
        if editButton.title == "Edit" {
            editButton.title = "Done"
            tableView.setEditing(true, animated: true)
        } else {
            editButton.title = "Edit"
            tableView.setEditing(false, animated: true)
            // TODO add some condition before allowing save, like tracking if items were actually rearranged.
            PHNAlbumManager.sharedInstance.save()
        }
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
//            galleryVC.userColor = userColor
//            galleryVC.userColorTag = userColorTag
        case SEGUE_EDIT_ALBUM:
            let indexPath = tableView.indexPath(for: sender as! UITableViewCell)
            let sentAlbum = PHNAlbumManager.sharedInstance.allAlbums[indexPath!.row]
            let navVC = segue.destination as! UINavigationController
            let detailVC = navVC.viewControllers[0] as! PHNAlbumDetailViewController
            detailVC.albumToEdit = sentAlbum
            detailVC.title = "Album Info"
            detailVC.delegate = self
//            detailVC.userColor = userColor
//            detailVC.userColorTag = userColorTag
        case SEGUE_ADD_ALBUM:
            let navVC = segue.destination as! UINavigationController
            let detailVC = navVC.viewControllers[0] as! PHNAlbumDetailViewController
            detailVC.delegate = self
            detailVC.title = "Create Album"
//            detailVC.userColor = userColor
//            detailVC.userColorTag = userColorTag
//        case SEGUE_QUICK_NOTE: cjm TODO decide whether or not we're removing quick note.
//            let album = PHNAlbumManager.sharedInstance.userQuickNote
//            let navVC = segue.destination as! UINavigationController
//            let vc = navVC.viewControllers[0] as! PHNFullImageViewController
//            vc.delegate = self
//            vc.index = 0
//            vc.albumName = album.albumTitle
//            vc.isQuickNote = true
////            vc.userColor = userColor
////            vc.userColorTag = userColorTag
//            vc.barsVisible = true
//            let numOpac = UserDefaults.standard.value(forKey: "noteOpacity") as? NSNumber
//            vc.noteOpacity = (numOpac != nil) ? CGFloat(exactly: numOpac!) : 0.75
        case SEGUE_VIEW_SETTINGS:
            let navVC = segue.destination as! UINavigationController
            navVC.modalPresentationStyle = .fullScreen
//            let vc = navVC.viewControllers[0] as! PHNSettingsViewController
        default:
            print("PHNAlbumsViewController performing segue with identifier: \(identifier)")
        }
    }
    
    /* cjm TODO planning to replace this popover with something else.
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
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
     */
    
    // MARK - UISearchBarDelegate
    
//    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
//        dismiss(animated: true, completion: nil)
//    }
}

//MARK: - PHNAlbumDetailViewControllerDelegate

extension PHNAlbumsViewController: PHNAlbumDetailViewControllerDelegate {
    
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
}

//MARK: - PHNCameraControllerDelegate

extension PHNAlbumsViewController: PHNCameraControllerDelegate {
    func camera(_ camera: PHNCameraController, didFinishProcessingPhotos photoNotes: [PhotoNote]?) {
        guard let confirmedPhotoNotes = photoNotes else {
            dismiss(animated: true, completion: nil)
            return
        }
        // Hold onto new Photo Notes so they can be added to a user selected album (see `func albumPickerViewController(_:didFinishPicking:)`
        newPhotoNotes = confirmedPhotoNotes
        
        // Present album picker to select an album to send new Photo Notes to.
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navVC = storyboard.instantiateViewController(withIdentifier: PHNAlbumPickerNavigationIdentifier) as! UINavigationController
        let albumPickerVC = navVC.topViewController as! PHNAlbumPickerViewController
        albumPickerVC.delegate = self
        albumPickerVC.title = "Select Destination"
        albumPickerVC.currentAlbumName = nil
        
        dismiss(animated: true) { [weak self] in
            self?.present(navVC, animated: true, completion: nil)
        }
        
        PHNAlbumManager.sharedInstance.save() // cjm TODO consider moving this...
    }
    
    func cameraDidCancel(error: CameraError?) {
        navigationController?.view.isUserInteractionEnabled = true
        
        // Check for error and alert the user to the issue if one exists.
        switch error {
        case nil:
            dismiss(animated: true, completion: nil)
        case .AccessDenied:
            let alertTitle = NSLocalizedString("Camera Access Denied",
                                      comment: "Camera Access Denied")
            let alertMessage = NSLocalizedString("Please allow Photo Notes permission to use the camera.",
                                        comment: "Please allow Photo Notes permission to use the camera.")
            let alert = UIAlertController(title: alertTitle,
                                        message: alertMessage,
                                 preferredStyle: .alert)
            
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString),
                UIApplication.shared.canOpenURL(settingsUrl)
            {
                let actionTitle = NSLocalizedString("Open Settings",
                                           comment: "Open Settings")
                let actionSettings = UIAlertAction(title: actionTitle,
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
            let dismissTitle = NSLocalizedString("Dismiss",
                                        comment: "Dismiss")
            let actionDismiss = UIAlertAction(title: dismissTitle, style: .cancel, handler: nil)
            alert.addAction(actionDismiss)
            
            dismiss(animated: true) { [weak self] in
                self?.present(alert, animated: true, completion: nil)
            }
        case .CameraUnavailable:
            let title = NSLocalizedString("No Camera Available",
                                 comment: "No Camera Available")
            let message = NSLocalizedString("There's no camera available for Photo Notes to use.",
                                   comment: "There's no camera available for Photo Notes to use.")
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let dismissTitle = NSLocalizedString("OK",
                                        comment: "OK")
            let actionDismiss = UIAlertAction(title: dismissTitle, style: .cancel, handler: nil)
            alert.addAction(actionDismiss)
            
            dismiss(animated: true) { [weak self] in
                self?.present(alert, animated: true, completion: nil)
            }
        }
    }
}

// MARK: - PHNAlbumPickerDelegate
extension PHNAlbumsViewController: PHNAlbumPickerDelegate {
    func albumPickerViewControllerDidCancel(_ controller: PHNAlbumPickerViewController) {
        newPhotoNotes = nil
        dismiss(animated: true, completion: nil)
    }
    
    func albumPickerViewController(_ controller: PHNAlbumPickerViewController, didFinishPicking album: PHNPhotoAlbum) {
        guard newPhotoNotes != nil, !newPhotoNotes!.isEmpty else {
            dismiss(animated: true, completion: nil)
            return
        }
        
        for image in newPhotoNotes! {
            image.configureWithDefaultValues()
            image.originalAlbum = album.albumTitle
        }
        album.addMultiple(newPhotoNotes!)
        PHNAlbumManager.sharedInstance.save()
        
        newPhotoNotes = nil
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Photo Grab Scene Delegate

extension PHNAlbumsViewController: PHNPhotoGrabCompletionDelegate {
    
    func photoGrabSceneDidCancel() {
        dismiss(animated: true, completion: nil)
    }
    
    /// Delegate method to handle import of selected images from one of the user photo libraries.
    /// - Parameter photos: The collection of selected photos to import.
    func photoGrabSceneDidFinishSelectingPhotos(_ photos: [PHAsset]) {
        var newImages = [PhotoNote]()
        // Pull the images, image creation dates, and image locations from each PHAsset in the received array.
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
                        if let data = imageData {
                            PHNServices.shared.writeImageData(data,
                                                forPhotoNote: assetImage)
                        }
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
                        PHNServices.shared.writeThumbnail( cResult,
                                                     forPhotoNote: assetImage)
                        assetImage.thumbnailNeedsRedraw = false
                        
//                        imageLoadGroup.leave()
                    }
                    imageLoadGroup.leave()
                })
            })
            assetImage.photoCreationDate = asset.creationDate
            newImages.append(assetImage)
        }
        
        newPhotoNotes = Array(newImages)
        
        imageLoadGroup.notify(queue: .main) { [weak self] in
            self?.navigationController?.view.isUserInteractionEnabled = true
            self?.dismiss(animated: true, completion: nil)
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let navVC = storyboard.instantiateViewController(withIdentifier: "AListPickerViewController") as! UINavigationController
            let aListPickerVC = navVC.topViewController as! PHNAlbumPickerViewController
//            aListPickerVC.delegate = self
            aListPickerVC.title = "Select Destination"
            aListPickerVC.currentAlbumName = nil
//            aListPickerVC.userColor = self?.userColor
//            aListPickerVC.userColorTag = self?.userColorTag
            
            self?.present(aListPickerVC, animated: true, completion: nil)
        }
    }
    
    
}
