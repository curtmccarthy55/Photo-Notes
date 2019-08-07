//
//  PHNAlbumDetailViewController.swift
//  Unroll2
//
//  Created by Curtis McCarthy on 8/4/19.
//  Copyright © 2019 Bluewraith. All rights reserved.
//

import UIKit

protocol PHNAlbumDetailViewControllerDelegate: class {
    func albumDetailViewControllerDidCancel(_ controller: PHNAlbumDetailViewController)
    func albumDetailViewController(_ controller: PHNAlbumDetailViewController, didFinishAddingAlbum album: PHNPhotoAlbum)
    func albumDetailViewController(_ controller: PHNAlbumDetailViewController, didFinishEditingAlbum album: PHNPhotoAlbum)
}

class PHNAlbumDetailViewController: UITableViewController, UIImagePickerControllerDelegate, UITextFieldDelegate {
    //MARK: - Properties
    
    //MARK: Internal Properties
    var albumToEdit: PHNPhotoAlbum?
    weak var delegate: PHNAlbumDetailViewControllerDelegate?
    var userColor: UIColor?
    var userColorTag: Int? // was NSNumber
    
    //MARK: FilePrivate & Private Properties
    @IBOutlet fileprivate weak var nameField: UITextField!
    @IBOutlet fileprivate weak var noteField: UITextView!
    
    //MARK: Scene Set Up
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        gestureRecognizer.cancelsTouchesInView = false
        tableView.addGestureRecognizer(gestureRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel",
                                                           style: .plain,
                                                          target: self,
                                                          action: #selector(cancelPressed))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done",
                                                            style: .done,
                                                           target: self,
                                                           action: #selector(donePressed))
        if albumToEdit == nil {
            navigationItem.rightBarButtonItem?.isEnabled = false
        } else if albumToEdit != nil {
            nameField.text = albumToEdit!.albumTitle
            noteField.text = albumToEdit!.albumNote
        }
        
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
        
        let backgroundView = UIImageView(image: UIImage(named: "AlbumListBackground"))
        backgroundView.contentMode = .scaleAspectFill
        tableView.backgroundView = backgroundView
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        nameField.becomeFirstResponder()
    }
    
    //MARK: BarButton Actions
    @objc func cancelPressed() {
        nameField.resignFirstResponder()
        noteField.resignFirstResponder()
        delegate?.albumDetailViewControllerDidCancel(self)
    }
    
    @objc func donePressed() {
        if let album = albumToEdit {
            if confirmNameNonDuplicate(nameField.text!) {
                return
            }
            album.albumTitle = nameField.text!
            album.albumNote = noteField.text
            
            nameField.resignFirstResponder()
            noteField.resignFirstResponder()
            
            delegate?.albumDetailViewController(self, didFinishEditingAlbum: album)
        } else {
            let name = nameField.text
            if confirmNameNonDuplicate(name!) {
                return
            }
            let note = noteField.text
            let album = PHNPhotoAlbum(withName: name!, andNote: note!)
            
            delegate?.albumDetailViewController(self, didFinishAddingAlbum: album)
        }
    }
    /*
     
 */
    /// Prevent the user from making an album with the same name as another album or using "Favorites"
    func confirmNameNonDuplicate(_ name: String) -> Bool {
        guard let album = albumToEdit else { return false }
        
        if name == "Favorites" {
            let favoritesAlert = UIAlertController(title: "Cannot Use \"Favorites\"", message: "The album name \"Favorites\" is reserved for when you favorite existing Photo Notes.", preferredStyle: .alert)
            let dismissAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            favoritesAlert.addAction(dismissAction)
            present(favoritesAlert, animated: true, completion: nil)
            return true
        } else if PHNAlbumManager.sharedInstance.existingAlbum(named: name) != nil &&
            album.albumTitle != name {
            let nameExistsAlert = UIAlertController(title: "Duplicate Album Name!",
                                                  message: "You have already created an album with this name.",
                                           preferredStyle: .alert)
            let dismissAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            nameExistsAlert.addAction(dismissAction)
            present(nameExistsAlert, animated: true, completion: nil)
            return true
        }
        return false
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }
    
    //MARK: - Table View Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            nameField.becomeFirstResponder()
        } else if indexPath.section == 1 {
            noteField.becomeFirstResponder()
        }
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return nil
    }
    
    //MARK: - Text View Delegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let oldString = textField.text,
         let r = Range(range, in: oldString),
         let currentTitleText = nameField.text?.replacingCharacters(in: r, with: string) {
            if currentTitleText.count > 0 {
                navigationItem.rightBarButtonItem?.isEnabled = true
            } else {
                navigationItem.rightBarButtonItem?.isEnabled = false
            }
        }
        return true
    }
    
    //MARK: - Keyboard Handling

    @objc func hideKeyboard(_ gestureRecognizer: UIGestureRecognizer) {
        let point = gestureRecognizer.location(in: tableView)
        let indexPath = tableView.indexPathForRow(at: point)
        
        if indexPath == nil {
            return
        }
        
        if noteField.isFirstResponder {
            noteField.resignFirstResponder()
        } else {
            nameField.resignFirstResponder()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        noteField.becomeFirstResponder()
        return true
    }
}
