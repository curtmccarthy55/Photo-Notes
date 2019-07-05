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

class PHNAlbumsTableViewController: UITableViewController, CJMADetailViewControllerDelegate, CJMFullImageViewControllerDelegate, UIPopoverPresentationControllerDelegate, PHNPopoverDelegate, PHNPhotoGrabCompletionDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CJMAListPickerDelegate {
    
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

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
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
            if PHNAlbumManager.sharedInstance.allAlbums.count == 0 {
                self?.navigationItem.prompt = "Tap + below to create a new Photo Notes album."
            } else {
                self?.navigationItem.prompt = nil
            }
        }
    }
    
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        if popoverPresent {
            dismiss(animated: true, completion: nil)
            popoverPresent = false
        }
    }
    
    // MARK: - TableView Data Source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return PHNAlbumManager.sharedInstance.allAlbums.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PHNAlbumsCellIdentifier, for: indexPath) as! PHNAlbumListTableViewCell
        let album = PHNAlbumManager.sharedInstance.allAlbums[indexPath.row]
        cell.configureWithTitle(album.albumTitle, count: album.albumPhotos.count)
        cell.configureThumbnail(forAlbum: album)
//        cell.accessoryType = .detailButton
        cell.showsReorderControl = true
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 1.0, height: 1.0))
        return view
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 4.0
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 1.0, height: 1.0))
        return view
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 4.0
    }
    
    //MARK: - TableView Delegate
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "ViewGallery", sender: tableView.cellForRow(at: indexPath))
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //MARK: - Photo Fetch
    
    func getCenterMaxSquareImageByCroppingImage(_ image: UIImage, andShrinkToSize newSize: CGSize) -> UIImage {
        // Get crop bounds
        var centerSquareSize: CGSize
        let originalImageWidth = CGFloat(image.cgImage!.width)
        let originalImageHeight = CGFloat(image.cgImage!.height)
        if originalImageHeight <= originalImageWidth {
            centerSquareSize.width = originalImageHeight
            centerSquareSize.height = originalImageHeight
        } else {
            centerSquareSize.width = originalImageWidth
            centerSquareSize.height = originalImageWidth
        }
        
        // Determine crop origin
        let x = (originalImageWidth - centerSquareSize.width) / 2.0
        let y = (originalImageHeight - centerSquareSize.height) / 2.0
        
        // Crop and create CGImageRef. This is where future improvement likely lies.
        let cropRect = CGRect(x: x, y: y, width: centerSquareSize.width, height: centerSquareSize.height)
        let imageRef = image.cgImage!.cropping(to: cropRect)!//CGImageCreateWithImageInRect(image.cgImage!, cropRect)
        let cropped = UIImage(cgImage: imageRef, scale: 0.0, orientation: image.imageOrientation)
        
        // Scale the image down to the smaller file size and return.
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        cropped.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    @IBAction func photoGrab() {
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
    
    func photosFromLibrary() {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            if status != .authorized {
                let adjustPrivacyController = UIAlertController(title: "Denied access to Photos", message: "You will need to give Photo Notes permission to import from your Photo Library.\nPlease allow Photo Notes access to your Photo Library by going to Settings>Privacy>Photos", preferredStyle: .alert)
                let dismiss = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
                adjustPrivacyController.addAction(dismiss)
                
                self?.present(adjustPrivacyController, animated: true, completion: nil)
            } else {
                self?.presentPhotoGrabViewController()
            }
        }
    }
    
    /// Present users photo library.
    func presentPhotoGrabViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navigationVC = storyboard.instantiateViewController(withIdentifier: "NavPhotoGrabViewController") as! UINavigationController
        let vc = navigationVC.topViewController as! PHNImportAlbumsVC
        vc.delegate = self
        vc.userColor = userColor
        vc.userColorTag = userColorTag
        vc.singleSelection = false
        
        present(navigationVC, animated: true, completion: nil)
    }
    
    //MARK: - Photo Grab Scene Delegate
    
    func photoGrabSceneDidCancel() {
        dismiss(animated: true, completion: nil)
    }
    
    func photoGrabSceneDidFinishSelectingPhotos(_ photos: [PHAsset]) {
        var newImages = [PhotoNote]()
        // Pull the images, image creation dates, and image locations from each PHAsset in the received array.
        let fileSerializer = PHNFileSerializer()
        
        if imageManager == nil {
            imageManager = PHCachingImageManager()
        }
        
        let imageLoadGroup = DispatchGroup()
        for asset in photos {
            var assetImage = PhotoNote()
            
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.version = .current
            
            imageLoadGroup.enter()
            autoreleasepool(invoking: {
                imageManager.requestImageData(for: asset, options: options, resultHandler: { (imageData, dataUTI, orientation, info) in
                    if let cInfo = info,
                        let degraded = cInfo[PHImageResultIsDegradedKey] as? Bool,
                        !degraded {
                        fileSerializer.writeObject(imageData, toRelativePath: assetImage.fileName)
//                        imageLoadGroup.leave()
                    }
                    imageLoadGroup.leave()
                })
            })
            
            imageLoadGroup.enter()
            autoreleasepool(invoking: { [weak self] in
                self?.imageManager.requestImage(for: asset, targetSize: CGSize(width: 120.0, height: 120.0), contentMode: .aspectFill, options: options, resultHandler: { (result, info) in
                    if let cResult = result,
                        let cInfo = info,
                        let degraded = cInfo[PHImageResultIsDegradedKey] as? Bool,
                        !degraded {
                        fileSerializer.writeImage(cResult, toRelativePath: assetImage.thumbnailFileName)
                        assetImage.thumbnailNeedsRedraw = false
                        
//                        imageLoadGroup.leave()
                    }
                    imageLoadGroup.leave()
                })
            })
            assetImage.photoCreationDate = asset.creationDate
            newImages.append(assetImage)
        }
        
        selectedPhotos = Array(newImages)
        
        imageLoadGroup.notify(queue: .main) { [weak self] in
            self?.navigationController?.view.isUserInteractionEnabled = true
            self?.dismiss(animated: true, completion: nil)
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let navVC = storyboard.instantiateViewController(withIdentifier: "AListPickerViewController") as! UINavigationController
            let aListPickerVC = navVC.topViewController as! PHNAListPickerViewController
            aListPickerVC.delegate = self
            aListPickerVC.title = "Select Destination"
            aListPickerVC.currentAlbumName = nil
            aListPickerVC.userColor = self?.userColor;
            aListPickerVC.userColorTag = self?.userColorTag;
            
            self?.present(aListPickerVC, animated: true, completion: nil)
        }
    }
    
    /*
 - (void)photoGrabSceneDidFinishSelectingPhotos:(NSArray *)photos {
     NSMutableArray *newImages = [[NSMutableArray alloc] init];
     //Pull the images, image creation dates, and image locations from each PHAsset in the received array.
     CJMFileSerializer *fileSerializer = [[CJMFileSerializer alloc] init];
     
     if (!self.imageManager) {
         self.imageManager = [[PHCachingImageManager alloc] init];
     }
 
     __block NSInteger counter = [photos count];
 //    __weak CJMGalleryViewController *weakSelf = self;
 
     dispatch_group_t imageLoadGroup = dispatch_group_create();
     for (int i = 0; i < photos.count; i++) {
         __block CJMImage *assetImage = [[CJMImage alloc] init];
         PHAsset *asset = (PHAsset *)photos[i];
     
         PHImageRequestOptions *options = [PHImageRequestOptions new];
         options.networkAccessAllowed = YES;
         options.version = PHImageRequestOptionsVersionCurrent;
     
         dispatch_group_enter(imageLoadGroup);
         @autoreleasepool {
             [self.imageManager requestImageDataForAsset:asset
             options:options
             resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
 
                 counter--;
                 if(![info[PHImageResultIsDegradedKey] boolValue]) {
                     [fileSerializer writeObject:imageData toRelativePath:assetImage.fileName];
                     dispatch_group_leave(imageLoadGroup);
                 }
             }];
         }
 
         dispatch_group_enter(imageLoadGroup);
         @autoreleasepool {
             [self.imageManager requestImageForAsset:asset targetSize:CGSizeMake(120.0, 120.0) contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage *result, NSDictionary *info) {
                 if(![info[PHImageResultIsDegradedKey] boolValue]) {
                     [fileSerializer writeImage:result toRelativePath:assetImage.thumbnailFileName];
                     assetImage.thumbnailNeedsRedraw = NO;
     
                     dispatch_group_leave(imageLoadGroup);
                 }
             }];
         }
 
         assetImage.photoCreationDate = [asset creationDate];
     
         [newImages addObject:assetImage];
     }
 
 
     //cjm 01/12
     //We need to basically execute a Transfer of the selected images to the AListPickerVC once the newImages array is done being loaded.
     self.selectedPhotos = [NSArray arrayWithArray:newImages];
     
     
     dispatch_group_notify(imageLoadGroup, dispatch_get_main_queue(), ^{
         self.navigationController.view.userInteractionEnabled = YES;
         [self dismissViewControllerAnimated:YES completion:nil];
     
         NSString *storyboardName = @"Main";
         UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
         UINavigationController *vc = (UINavigationController *)[storyboard instantiateViewControllerWithIdentifier:@"AListPickerViewController"];
         CJMAListPickerViewController *aListPickerVC = (CJMAListPickerViewController *)[vc topViewController];
         aListPickerVC.delegate = self;
         aListPickerVC.title = @"Select Destination";
         aListPickerVC.currentAlbumName = nil;
         aListPickerVC.userColor = self.userColor;
         aListPickerVC.userColorTag = self.userColorTag;
         [self presentViewController:vc animated:YES completion:nil];
     });
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
