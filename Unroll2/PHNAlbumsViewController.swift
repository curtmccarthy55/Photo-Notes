//
//  PHNAlbumsViewController.swift
//  Unroll2
//
//  Created by Curtis McCarthy on 12/3/21.
//  Copyright © 2021 Bluewraith. All rights reserved.
//

import Foundation
import UIKit

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
    }
    
    /// Register table view cells for reuse.
    func registerCells() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: PHNAlbumsCellIdentifier)
    }
    
    /// Sets up the search controller.
    func prepareSearchBar() {
        searchController.delegate = self
//        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Photo Notes"
        definesPresentationContext = true
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
    
    /// Responds to user tapping the magnifying glass bar button.  Presents the search controller.
    @IBAction func tappedSearch(_ sender: Any?) {
        present(searchController, animated: true, completion: nil)
    }
    
    //MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PHNAlbumsCellIdentifier, for: indexPath)
        cell.contentView.backgroundColor = .white
        cell.textLabel?.text = "test cell text"
        cell.textLabel?.textColor = .black
        return cell
    }
    
    //MARK: - UISearchBarDelegate
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        dismiss(animated: true, completion: nil)
    }
}
