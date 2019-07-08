//
//  PHNAlbumPickerViewController.swift
//  Unroll2
//
//  Created by Curtis McCarthy on 7/5/19.
//  Copyright © 2019 Bluewraith. All rights reserved.
//

import UIKit

protocol PHNAlbumPickerDelegate: class {
    func albumPickerViewControllerDidCancel(_ controller: PHNAlbumPickerViewController)
    func albumPickerViewController(_ controller: PHNAlbumPickerViewController, didFinishPicking album: PHNPhotoAlbum)
}

private let CELL_REUSE_IDENTIFIER = "AlbumCell"
private let CELL_NIB_NAME = "PHNAlbumListTableViewCell"

class PHNAlbumPickerViewController: UITableViewController {
    weak var delegate: PHNAlbumPickerDelegate?
    var currentAlbumName: String?
    var userColor: UIColor?
    var userColorTag: Int?
    
    private var selectedAlbum: PHNPhotoAlbum?
    private var transferAlbums = [PHNPhotoAlbum]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let nib = UINib(nibName: CELL_NIB_NAME, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: CELL_REUSE_IDENTIFIER)
        tableView.rowHeight = 120 // was 80
        
        let albumArray = PHNAlbumManager.sharedInstance.allAlbums
        for album in albumArray {
            if (album.albumTitle != "Favorites") && (album.albumTitle != "CJMQuickNote") {
                transferAlbums.append(album)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel",
                                                           style: .plain,
                                                          target: self,
                                                          action: #selector(cancelTapped))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(doneTapped))
        
        if userColorTag != 5 && userColorTag != 7 {
            navigationController?.navigationBar.barStyle = .black
            navigationController?.navigationBar.tintColor = .white
            navigationController?.toolbar.tintColor = .white
            navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white]
        } else {
            navigationController?.navigationBar.barStyle = .default
            navigationController?.navigationBar.tintColor = .black
            navigationController?.toolbar.tintColor = .black
            navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.black]
        }
        
        navigationController?.navigationBar.barTintColor = userColor
        navigationController?.toolbar.barTintColor = userColor
    }
    
    //MARK: - Button Actions
    
    @objc func cancelTapped() {
        delegate?.albumPickerViewControllerDidCancel(self)
    }
    
    /// If user picks the current album, display an alert.  Otherwise, move photos to new album.
    @objc func doneTapped() {
        guard selectedAlbum != nil else {
            let alert = UIAlertController(title: "Selection Error", message: "An error occurred with the selection.  Please select an album and tap 'Done' again.", preferredStyle: .alert)
            let dismiss = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alert.addAction(dismiss)
            present(alert, animated: true, completion: nil)
            return
        }
        
        if selectedAlbum!.albumTitle == currentAlbumName {
            let alert = UIAlertController(title: "Choose A Different Album", message: "Your current selection already exists in \(selectedAlbum?.albumTitle ?? "this album").\nPlease select a different album or tap Cancel to exit.", preferredStyle: .alert)
            let dismissAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alert.addAction(dismissAction)
            
            present(alert, animated: true, completion: nil)
        } else {
            delegate?.albumPickerViewController(self, didFinishPicking: selectedAlbum!)
        }
    }

    // MARK: - TableView Data Source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transferAlbums.count;
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_REUSE_IDENTIFIER, for: indexPath) as! PHNAlbumListTableViewCell
        
        let album = transferAlbums[indexPath.row]
        cell.configureWithTitle(album.albumTitle, count: album.albumPhotos.count)
        cell.configureThumbnail(forAlbum: album)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        // replaces blank bottom rows with blank space in the tableView
        return UIView()
    }
    
    //MARK: - TableView Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        navigationItem.rightBarButtonItem?.isEnabled = true
        selectedAlbum = transferAlbums[indexPath.row]
    }
}
