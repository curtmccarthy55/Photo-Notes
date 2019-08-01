//
//  PHNImportAlbumsViewController.swift
//  Unroll2
//
//  Created by Curtis McCarthy on 8/1/19.
//  Copyright © 2019 Bluewraith. All rights reserved.
//

import UIKit
import Photos

protocol PHNPhotoGrabCompletionDelegate: class {
    func photoGrabSceneDidCancel()
    func photoGrabSceneDidFinishSelectingPhotos(_ photos: [PHAsset])
}

fileprivate let SEGUE_IDENTIFIER = "ViewCollection"
fileprivate let CELL_IDENTIFIER = "AlbumCell"

fileprivate enum Section {
    case allPhotos, smartAlbums, userCollections
}

class PHNImportAlbumsViewController: UITableViewController {
    //MARK: - Properties
    
    //MARK: Internal Properties
    weak var delegate: PHNPhotoGrabCompletionDelegate?
    var userColor: UIColor?
    var userColorTag: Int? // was NSNumber
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

        let nib = UINib(nibName: "CJMAListTableViewCell", bundle: nil)
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
    /*
         
 */
    }
    
    func cancelPressed() {
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
        <#code#>
    }
    /*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CJMAListTableViewCell *cell = (CJMAListTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CJMAListCellIdentifier forIndexPath:indexPath];

    PHAsset *asset;
    if (indexPath.section == 0) {
        NSLog(@"should be showing All Photos cell");
        [cell configureWithTitle:@"All Photos" withAlbumCount:(int)self.allPhotos.count];
        asset = self.allPhotos.lastObject;
    } else if (indexPath.section == 1) {
        PHAssetCollection *assetCollection = self.smartAlbums[indexPath.row];
        PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:assetCollection options:self.ascendingOptions];
        asset = result.lastObject;

        [cell configureWithTitle:assetCollection.localizedTitle withAlbumCount:(int)result.count];
    } else if (indexPath.section == 2) {
        PHCollection *collection = self.userCollections[indexPath.row];
        if ([collection isKindOfClass:[PHAssetCollection class]]) {
            PHAssetCollection *assetCollection = (PHAssetCollection *)collection;
            PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:assetCollection options:self.ascendingOptions];
            asset = result.lastObject;

            [cell configureWithTitle:assetCollection.localizedTitle withAlbumCount:(int)result.count];
        } else if ([collection isKindOfClass:[PHCollectionList class]]) {

        }
    }

    [self.imageManager requestImageForAsset:asset
    targetSize:cell.frame.size
    contentMode:PHImageContentModeAspectFill
    options:nil
    resultHandler:^(UIImage *result, NSDictionary *info) {
        if (result != nil) {
            cell.cellThumbnail.image = result;
        } else {
            cell.cellThumbnail.image = [UIImage imageNamed:@"NoImage"];
        }
    }];

    return cell;
}
 */
    

}
