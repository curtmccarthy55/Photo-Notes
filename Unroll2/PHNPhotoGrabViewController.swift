//
//  PHNPhotoGrabViewController.swift
//  Unroll2
//
//  Created by Curtis McCarthy on 8/2/19.
//  Copyright © 2019 Bluewraith. All rights reserved.
//

import UIKit
import Photos

fileprivate let CELL_IDENTIFIER = "GrabCell"

class PHNPhotoGrabViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UINavigationControllerDelegate {
    //MARK: - Properties
    
    //MARK: Internal Properties
    
    weak var delegate: PHNPhotoGrabCompletionDelegate?
    var userColor: UIColor
    var userColorTag: Int // Was NSNumber
    var singleSelection: Bool
    var fetchResult: PHFetchResult?
    
    //MARK: Private Properties
    
    @IBOutlet weak var collectionView: UICollectionView!
    var imageManager = PHCachingImageManager()
    
    //MARK: - Scene Set Up
    
    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.allowsMultipleSelection = singleSelection ? false : true
        // cjm album fetch. PHAsset fetch call made here.
        // fetchResult = PHAsset.fetchAssets(with: .image, options: nil)
        navigationItem.title = "Select Photos"
        
//        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(donePressed))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(donePressed))
        navigationItem.rightBarButtonItem?.isEnabled = false
        
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
        
        // Scroll to bottom before displaying.  TODO: this can be improved.
        let pageSize = view.bounds.size
        let contentOffSet = CGPoint(x: 0, y: pageSize.height * fetchResult!.count - 1)
        collectionView.setContentOffset(contentOffSet, animated: false)
    }
    
    //MARK: - CollectionView Data Source
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResult!.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_IDENTIFIER, for: indexPath) as! PHNGrabCell
        cell.cellSelectCover.isHidden = true
        
        // Check if indexPath has been selected and reveal its cell's selectCover if it has been.
        if collectionView.indexPathsForSelectedItems.count > 0 && collectionView.indexPathsForSelectedItems?.contains(indexPath) {
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .none)
            cell.cellSelectCover.isHidden = false
        }
        
        let asset = fetchResult![indexPath.row]
        cell.asset = asset
        imageManager.requestImage(for: asset, targetSize: cell.frame.size, contentMode: .aspectFill, options: nil) { (result, info) in
            cell.cellImage.image = result
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedCell = collectionView.cellForItem(at: indexPath) as! PHNGrabCell
        selectedCell.cellSelectCover.isHidden = false
        if navigationItem.rightBarButtonItem?.isEnabled == false {
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let selectedCell = collectionView.cellForItem(at: indexPath) as! PHNGrabCell
        selectedCell.cellSelectCover.isHidden = true
        if collectionView.indexPathsForSelectedItems.count == 0 {
            navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }
    
    //MARK: - Actions
    
    func cancelPressed() {
        delegate?.photoGrabSceneDidCancel()
    }
    
    func donePressed() {
        let hudView = PHNHudView.hud(inView: view, withType: "Pending", animated: true)
        hudView.text = "Importing"
        
        let selectedItems = collectionView.indexPathsForSelectedItems
        
        var pickedPhotos = [PHAsset]()
        for (index, asset) in selectedItems!.enumerated() {
            let indexPath = selectedItems![index]
            let asset = fetchResult![indexPath.item]
            pickedPhotos.append(asset)
        }
        delegate?.photoGrabSceneDidFinishSelectingPhotos(pickedPhotos)
    }
    
    //MARK: - UICollectionViewFlowLayout Delegate
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if UIDevice.current.orientation == .landscapeLeft ||
            UIDevice.current.orientation == .landscapeRight {
            let viewWidth = lroundf(Float(collectionView.frame.size.width))
            let cellWidth = (viewWidth / 5) - 2
            return CGSize(width: cellWidth, height: cellWidth)
        } else {
            let viewWidth = lroundf(Float(collectionView.frame.size.width))
            let cellWidth = (viewWidth / 4) - 2
            return CGSize(width: cellWidth, height: cellWidth)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
    }
    
    // Resizes collectionView cells per sizeForItemAtIndexPath when user rotates device.
    func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        super.willRotate(to: toInterfaceOrientation, duration: duration)
        collectionView.collectionViewLayout.invalidateLayout()
    }
}