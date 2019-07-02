//
//  PHNAlbumsTableViewController.swift
//  Unroll2
//
//  Created by Curtis McCarthy on 6/28/19.
//  Copyright © 2019 Bluewraith. All rights reserved.
//

import UIKit
import Photos
/*
open class CJMAListViewController : UITableViewController, CJMADetailViewControllerDelegate, CJMFullImageViewControllerDelegate {
    
    
    open func openCamera()
}
 */

class PHNAlbumsTableViewController: UITableViewController, CJMADetailViewControllerDelegate, CJMFullImageViewControllerDelegate, UIPopoverPresentationControllerDelegate, CJMPopoverDelegate, PHNPhotoGrabCompletionDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CJMAListPickerDelegate {
    
//    #define CJMAListCellIdentifier @"AlbumCell"
    let PHNAlbumsCellIdentifier = "AlbumCell"
    
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
    var imageManager: PHCachingImageManager

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let nib = UINib(nibName: "CJMAListTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: PHNAlbumsCellIdentifier)
        tableView.rowHeight = 120 // was 80
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        userColors()
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
    
    func userColors() {
        var tag = 0
        var red, green, blue: NSNumber
        if let dic = UserDefaults.standard.value(forKey: "PhotoNotesColor") as? [String : NSNumber] {
            red = dic["PhotoNotesRed"]!
            green = dic["PhotoNotesGreen"]!
            blue = dic["PhotoNotesBlue"]!
            tag = dic["PhotoNotesColorTag"] as! Int
            
            userColor = UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: 1.0)
            userColorTag = tag
        } else {
            userColor = UIColor(red: 60.0/255.0, green: 128.0/255.0, blue: 194.0/255.0, alpha: 1.0)
            userColorTag = tag
        }
        if (tag != 5) && (tag != 7) { // Yellow or White theme will require dark text and icons.
            navigationController?.navigationBar.barStyle = .black
            navigationController?.navigationBar.tintColor = .white
            navigationController?.toolbar.tintColor = .white
            navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white]
        } else { // Darker color themese will require light text and icons.
            navigationController?.navigationBar.barStyle = .default
            navigationController?.navigationBar.tintColor = .black
            navigationController?.toolbar.tintColor = .black
            navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.black]
        }
        
        navigationController?.navigationBar.tintColor = userColor
        navigationController?.toolbar.tintColor = userColor
    }
    
    func noAlbumsPopUp() { //If there are no albums, prompt the user to create one after a delay.
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            if PHNAlbumManager.shared.allAlbums.count == 0 {
                self?.navigationItem.prompt = "Tap + below to create a new Photo Notes album."
            } else {
                self?.navigationItem.prompt = nil
            }
        }
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}