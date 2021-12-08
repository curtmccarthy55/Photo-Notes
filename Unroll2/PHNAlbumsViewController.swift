//
//  PHNAlbumsViewController.swift
//  Unroll2
//
//  Created by Curtis McCarthy on 12/3/21.
//  Copyright © 2021 Bluewraith. All rights reserved.
//

import Foundation
import UIKit

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
    
    // ivars
    /// A temporary container for newly created Photo Notes, imported from a user library or captured by the camera.
    var newPhotoNotes: [PhotoNote]?
    /// Populated while camera in use.  May not need to hold onto this...
    var camera: PHNCamera?
    
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
            self.camera = PHNCamera(presentingView: self)
            self.camera?.openCamera()
            self.camera?.delegate = self
        })
        // Access photo library
        let libraryAction = UIAlertAction(title: "Choose From Library", style: .default, handler: { [weak self] action in
//            self?.photosFromLibrary()
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
    
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Navigate to the selected album's gallery.
        performSegue(withIdentifier: SEGUE_VIEW_GALLERY, sender: tableView.cellForRow(at: indexPath))
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK - UISearchBarDelegate
    
//    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
//        dismiss(animated: true, completion: nil)
//    }
}

//MARK: - PHNCameraDelegate

extension PHNAlbumsViewController: PHNCameraDelegate {
    func camera(_ camera: PHNCamera, didFinishProcessingPhotos photoNotes: [PhotoNote]?) {
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
            image.selectCoverHidden = true
            image.photoTitle = "No Title Created "
            image.photoNote = "Tap Edit to change the title and note!"
            image.photoFavorited = false
            image.originalAlbum = album.albumTitle
        }
        album.addMultiple(newPhotoNotes!)
        PHNAlbumManager.sharedInstance.save()
        
        newPhotoNotes = nil
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        
        dismiss(animated: true, completion: nil)
    }
}
