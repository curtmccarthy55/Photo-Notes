//
//  PHNImportAlbumsViewController.swift
//  Unroll2
//
//  Created by Curtis McCarthy on 8/1/19.
//  Copyright © 2019 Bluewraith. All rights reserved.
//

import UIKit
import Photos

/// Protocol for handling image import processing and cancellation.
protocol PHNPhotoGrabCompletionDelegate: class {
    func photoGrabSceneDidCancel()
    func photoGrabSceneDidFinishSelectingPhotos(_ photos: [PHAsset])
}

fileprivate let SEGUE_IDENTIFIER = "ViewCollection"
fileprivate let CELL_IDENTIFIER = "AlbumCell"

fileprivate enum Section {
    case allPhotos, smartAlbums, userCollections
}

/// View controller to display user Photos albums.
class PHNImportAlbumsViewController: UITableViewController {
    //MARK: - Properties
    
    //MARK: Internal Properties
    weak var delegate: PHNPhotoGrabCompletionDelegate?
    var userColor: UIColor?
    var singleSelection: Bool?
    
    //MARK: Private Properties
    
    var allPhotos: PHFetchResult<PHAsset>?
    var smartAlbums: PHFetchResult<PHAssetCollection>?
    var userCollections: PHFetchResult<PHCollection>?
    var sectionLocalizedTitles: [String]?
    var imageManager = PHCachingImageManager()
    var ascendingOptions: PHFetchOptions?
    
    var selectedIndex: IndexPath?
    
    //MARK: - Scene Set Up
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let nib = UINib(nibName: "PHNAlbumListTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: CELL_IDENTIFIER)
        tableView.rowHeight = 80
        navigationItem.title = "Photos"
        sectionLocalizedTitles = ["", "Library", "My Albums"]
        
        // Create a PHFetchResult object for each section in the table view.
        ascendingOptions = PHFetchOptions()
        ascendingOptions?.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        allPhotos = PHAsset.fetchAssets(with: ascendingOptions)
        smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum,
                                                           subtype: .albumRegular,
                                                           options: nil)
        /*
         TODO we should remove Recently Deleted and All Photos from this collection.  Need to see what All Photos collection name actually is though.
         We'll need to set up a fetchOption that excludes these albums and include that in the smartAlbums fetch.
         I should also filter out FetchResults that have count == 0.
         */
        
        userCollections = PHCollectionList.fetchTopLevelUserCollections(with: nil)
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelPressed))
        
        appearanceForPreferredColor()
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
        
        navigationController?.navigationBar.barTintColor = userColor
        navigationController?.toolbar.barTintColor = userColor
    }
    
    @objc func cancelPressed() {
        delegate?.photoGrabSceneDidCancel()
    }

    // MARK: - Table View Data Source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return smartAlbums!.count
        case 2:
            return userCollections!.count
        default:
            //display some error message?
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_IDENTIFIER, for: indexPath) as! PHNAlbumListTableViewCell
        
        var asset: PHAsset?
        if indexPath.section == 0 {
            #if DEBUG
            print("Should be showing All Photos cell")
            #endif
            cell.configureWithTitle("All Photos", count: (allPhotos?.count ?? 0))
            asset = allPhotos?.lastObject
        } else if indexPath.section == 1 {
            let assetCollection = smartAlbums?[indexPath.row]
            let result = PHAsset.fetchAssets(in: assetCollection!, options: ascendingOptions)
            asset = result.lastObject
            
            cell.configureWithTitle(assetCollection!.localizedTitle!, count: result.count)
        } else if indexPath.section == 2 {
            let collection = userCollections![indexPath.row]
            if collection is PHAssetCollection {
                let assetCollection = collection as! PHAssetCollection
                let result = PHAsset.fetchAssets(in: assetCollection, options: ascendingOptions)
                asset = result.lastObject
                
                cell.configureWithTitle(assetCollection.localizedTitle!, count: result.count)
            } else if collection is PHCollectionList {
                // TODO
            }
        }
        
        if asset != nil {
            imageManager.requestImage(for: asset!, targetSize: cell.frame.size, contentMode: .aspectFill, options: nil) { (result, info) in
                if result != nil {
                    cell.cellThumbnail.image = result
                } else {
                    cell.cellThumbnail.image = UIImage(named: "NoImage")
                }
            }
        } else {
            cell.cellThumbnail.image = UIImage(named: "NoImage")
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionLocalizedTitles![section]
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as? UITableViewHeaderFooterView
        header?.textLabel?.textColor = .white
        header?.backgroundColor = .clear
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndex = indexPath
        performSegue(withIdentifier: SEGUE_IDENTIFIER, sender: nil)
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! PHNPhotoGrabViewController
        vc.delegate = delegate
        vc.singleSelection = singleSelection!
        
        if selectedIndex?.section == 0 {
            #if DEBUG
            print("should be showing All Photos cell")
            #endif
            vc.fetchResult = allPhotos
            vc.title = "All Photos"
        } else if selectedIndex?.section == 1 {
            let assetCollection = smartAlbums![selectedIndex!.row]
            let result = PHAsset.fetchAssets(in: assetCollection, options: ascendingOptions)
            vc.fetchResult = result
            vc.title = assetCollection.localizedTitle!
        } else if selectedIndex?.section == 2 {
            let collection = userCollections![selectedIndex!.row]
            if collection is PHAssetCollection {
                let assetCollection = collection as! PHAssetCollection
                let result = PHAsset.fetchAssets(in: assetCollection, options: ascendingOptions)
                vc.fetchResult = result
                vc.title = assetCollection.localizedTitle!
            } else if collection is PHCollectionList {
                // TODO
            }
        }
    }
    /*
     
 */
    

}
