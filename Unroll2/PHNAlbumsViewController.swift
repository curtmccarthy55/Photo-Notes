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
    
    // MARK: - UISearchBarDelegate
    
//    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
//        dismiss(animated: true, completion: nil)
//    }
}
