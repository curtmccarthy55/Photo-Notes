//
//  PHNSettingsViewController.swift
//  Unroll2
//
//  Created by Curtis McCarthy on 8/4/19.
//  Copyright © 2019 Bluewraith. All rights reserved.
//

import UIKit
import SafariServices
import MessageUI
import StoreKit
import Photos

enum ThemeColor: Int {
    case kPhotoNotesBlue = 0
    case kPhotoNotesRed
    case kPhotoNotesBlack
    case kPhotoNotesPurple
    case kPhotoNotesOrange
    case kPhotoNotesYellow
    case kPhotoNotesGreen
    case kPhotoNotesWhite
}

class PHNSettingsViewController: UITableViewController, PHNPhotoGrabCompletionDelegate, SFSafariViewControllerDelegate, MFMailComposeViewControllerDelegate {
    //MARK: - Properties
    
    @IBOutlet weak var btnDone: UIBarButtonItem!
    @IBOutlet weak var sldOpacity: UISlider!
    @IBOutlet weak var noteView: UIView!
    @IBOutlet weak var lblOpacity: UITextField!
    @IBOutlet weak var sampleImage: UIImageView!
    var finalVal: CGFloat?
    
    var fetchResult: PHFetchResult?
    var imageManager: PHCachingImageManager?
    
    @IBOutlet weak var whiteButton: UIButton!
    
    var colorButtons: [UIButton]!
    var userColorTag: Int? // was NSNumber
    var userColor: UIColor?
    var colorChanged = false
    
    @IBOutlet weak var qnThumbnail: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        btnDone.isEnabled = false
        
        if let dic = UserDefaults.standard.value(forKey: "PhotoNotesColor") as? NSDictionary {
            if let red = dic.value(forKey: "PhotoNotesRed") as? NSNumber,
                let green = dic.value(forKey: "PhotoNotesGreen") as? NSNumber,
                let blue = dic.value(forKey: "PhotoNotesBlue") as? NSNumber {
                userColor = UIColor(red: red.floatValue, green: green.floatValue, blue: blue.floatValue, alpha: 1.0)
            } else {
                userColor = UIColor(red: 60.0/255.0, green: 128.0/255.0, blue: 194.0/255.0, alpha: 1.0)
            }
            
            if let number = dic.value(forKey: "PhotoNotesColorTag") as? NSNumber,
                let currentTag = Int(exactly: number!) {
                userColorTag = currentTag
            } else {
                userColorTag = 0
            }
        } else {
            userColor = UIColor(red: 60.0/255.0, green: 128.0/255.0, blue: 194.0/255.0, alpha: 1.0)
            userColorTag = 0
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
        
        // Set current opacity.
        var opacity: Float
        if let currentOpacity = UserDefaults.standard.value(forKey: "noteOpacity") as? NSNumber {
            opacity = currentOpacity.floatValue
        } else {
            opacity = 0.75
        }
        noteView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: opacity)
        lblOpacity.text = "\(roundf(opacity * 100))%"
        sldOpacity.setValue((opacity * 100.0), animated: false)
        
        // Set current color
        whiteButton.layer.borderWidth = 1.0
        whiteButton.layer.borderColor = UIColor.black.cgColor
        let button = colorButtons[userColorTag!]
        button.layer.borderWidth = 2.0
        button.layer.borderColor = UIColor.green.cgColor
        
        for btn in colorButtons {
            btn.accessibilityIgnoresInvertColors = true
        }
        qnThumbnail.accessibilityIgnoresInvertColors = true
        noteView.accessibilityIgnoresInvertColors = true
        sampleImage.accessibilityIgnoresInvertColors = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.isTranslucent = true
        displayQNThumbnail()
        
        let backgroundView = UIImageView(image: UIImage(named: "AlbumListBackground"))
        backgroundView.contentMode = .scaleAspectFill
        tableView.backgroundView = backgroundView
    }
    
    //MARK: - IBActions
    
    @IBAction func doneAction(_ sender: Any?) {
        let opacity = UserDefaults.standard.value(forKey: "noteOpacity") as? NSNumber
        if opacity?.floatValue != sldOpacity.value {
            let newOpac = NSNumber(value: sldOpacity.value / 100)
            UserDefaults.standard.set(newOpac, forKey: "noteOpacity") // TODO make Int?
        }
        
        if colorChanged {
            let dic = selectedColorWithTag(userColorTag!)
            UserDefaults.standard.set(dic, forKey: "PhotoNotesColor")
        }
        
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelAction(_ sender: Any?) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func standardColor(_ sender: UIButton) {
        if !btnDone.isEnabled {
            btnDone.isEnabled = true
        }
        colorChanged = true
        
        let currentcolor = colorButtons[userColorTag!]
        if currentcolor.tag == 7 {
            currentcolor.layer.borderWidth = 1.0
            currentcolor.layer.borderColor = UIColor.black.cgColor
        } else {
            currentcolor.layer.borderWidth = 0.0
        }
        
        sender.layer.borderWidth = 2.0
        sender.layer.borderColor = UIColor.green.cgColor
        
        let numTag = NSNumber(integerLiteral: sender.tag)
        userColorTag = numTag.intValue
        
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
        
        let dic = selectedColorWithTag(sender.tag)
        let red = dic.value(forKey: "PhotoNotesRed") as? NSNumber
        let green = dic.value(forKey: "PhotoNotesGreen") as? NSNumber
        let blue = dic.value(forKey: "PhotoNotesBlue") as? NSNumber
        
        userColor = UIColor(red: red!.floatValue, green: green!.floatValue, blue: blue!.floatValue, alpha: 1.0)
        navigationController?.navigationBar.barTintColor = userColor
//        sldOpacity.thumbTintColor = userColor
    }
    
    func selectedColorWithTag(_ tag: Int) -> NSDictionary {
        var dictionary = NSDictionary<String, NSNumber>()
        var red, green, blue: NSNumber
        var selectedTag: NSNumber
        
        switch tag {
        case kPhotoNotesBlue.rawValue:
            red = NSNumber(value: 60.0/255.0)
            green = NSNumber(value: 128.0/255.0)
            blue = NSNumber(value: 194.0/255.0)
            selectedTag = 0
        case kPhotoNotesRed.rawValue:
            red = NSNumber(value: 0.81)
            green = NSNumber(value: 0.21)
            blue = NSNumber(value: 0.2)
            selectedTag = 1
        case kPhotoNotesBlack.rawValue:
            red = NSNumber(value: 0.26)
            green = NSNumber(value: 0.26)
            blue = NSNumber(value: 0.26)
            selectedTag = 2
        case kPhotoNotesPurple.rawValue:
            red = NSNumber(value: 0.67)
            green = NSNumber(value: 0.26)
            blue = NSNumber(value: 0.73)
            selectedTag = 3
        case kPhotoNotesOrange.rawValue:
            red = NSNumber(value: 0.93)
            green = NSNumber(value: 0.55)
            blue = NSNumber(value: 0.01)
            selectedTag = 4
        case kPhotoNotesYellow:
            red = NSNumber(value: 0.95)
            green = NSNumber(value: 0.95)
            blue = NSNumber(value: 0.34)
            selectedTag = 5
        case kPhotoNotesGreen:
            red = NSNumber(value: -0.08)
            green = NSNumber(value: 0.56)
            blue = NSNumber(value: -0.01)
            selectedTag = 6
        case kPhotoNotesWhite:
            red = NSNumber(value: 1.0)
            green = NSNumber(value: 1.0)
            blue = NSNumber(value: 1.0)
            selectedTag = 7
        default:
            break
        }
        
        dictionary.setValue(red, forKey: "PhotoNotesRed")
        dictionary.setValue(green, forKey: "PhotoNotesGreen")
        dictionary.setValue(blue, forKey: "PhotoNotesBlue")
        dictionary.setValue(selectedTag, forKey: "PhotoNotesColorTag")
        
        return dictionary
    }
    
    //MARK: - Opacity Slider
    
    @IBAction func slider(_ sender: UISlider) {
        let oVal = sender.value
        lblOpacity.text = "\(roundf(oVal))%"
        noteView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: (oVal / 100))
        lblOpacity.alpha = 1.0
        
        if !btnDone.isEnabled {
            btnDone.isEnabled = true
        }
    }
    
    //MARK: - PHNPhotoGrabber Methods and Delegate
    
    func presentPhotoGrabViewController() {
        let sbName = "Main"
        let storyboard = UIStoryboard(name: sbName, bundle: nil)
        let navigationVC = storyboard.instantiateViewController(withIdentifier: "NavPhotoGrabViewController") as! UINavigationController
        let vc = navigationVC.topViewController as! PHNImportAlbumsViewController
        vc.delegate = self
        vc.userColor = userColor
        vc.userColorTag = userColorTag
        vc.singleSelection = true
        
        present(navigationVC, animated: true, completion: nil)
    }
    
    func photoGrabSceneDidCancel() {
        dismiss(animated: true, completion: nil)
        let indexPath = IndexPath(row: 0, section: 1)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    /// Iterate through array of selected photos, convert them to Photo Note instances, and add to the current album.
    func photoGrabSceneDidFinishSelectingPhotos(_ photos: [PHAsset]) {
        var newImages = [PhotoNote]()
        // Pull the images, image creation dates, and image locations from each PHAsset in the received array.
        let fileSerializer = PHNFileSerializer()
        
        if imageManager != nil {
            imageManager = PHCachingImageManager()
        }
        
        let imageLoadGroup = DispatchGroup()
        for asset in photos {
            let assetImage = PhotoNote()
            
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.version = .current
            
            imageLoadGroup.enter()
            autoreleasepool(invoking: {
                imageManager!.requestImageData(for: asset, options: options, resultHandler: { (imageData, dataUTI, orientation, info) in
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
            autoreleasepool(invoking: {
                imageManager!.requestImage(for: asset,
                                    targetSize: CGSize(width: 120.0, height: 120.0),
                                   contentMode: .aspectFill,
                                       options: options,
                                 resultHandler: { (result, info) in
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
            assetImage.setInitialValuesWithAlbum("CJMQuickNote")
            assetImage.photoCreationDate = Date()
            
            newImages.append(assetImage)
        }
        
        let album = PHNAlbumManager.sharedInstance.userQuickNote
        let newImage = newImages[0]
        if album.albumPhotos.count > 0 {
            let oldImage = album.albumPhotos[0]
            newImage.photoTitle = oldImage.photoTitle
            newImage.photoNote = oldImage.photoNote
            newImage.photoCreationDate = oldImage.photoCreationDate
        }
        PHNAlbumManager.sharedInstance.albumWithName( "CJMQuickNote",
                                        deleteImages: album.albumPhotos)
        
        album.add(newImage)
        btnDone.isEnabled = true
        
        imageLoadGroup.notify(queue: .main) { [weak self] in
            self?.navigationController?.view.isUserInteractionEnabled = true
            self?.dismiss(animated: true, completion: nil)
            PHNAlbumManager.sharedInstance.save()
            self?.displayQNThumbnail()
            self?.navigationController?.view.isUserInteractionEnabled = true //TODO why the repeat?
        }
    }
    
    func displayQNThumbnail() {
        let album = PHNAlbumManager.sharedInstance.userQuickNote
        if album.albumPhotos.count > 0 {
            let qnImage = album.albumPhotos[0]
            
            PHNServices.sharedInstance.fetchThumbnailForImage(photoNote: qnImage) { [weak self] (thumbnail) in
                // If thumbnail not properly captured during import, create one.
                if thumbnail?.size.width == 0 {
                    qnImage.thumbnailNeedsRedraw = true
                    PHNServices.sharedInstance.removeImageFromCache(qnImage)
                } else {
                    self?.qnThumbnail.image = thumbnail
                }
            }
        } else {
            qnThumbnail.image = UIImage(named: "QuickNote PN Background")
        }
    }
    
    func photosFromLibrary() {
        PHPhotoLibrary.requestAuthorization { [weak self] (status) in
            if status != .authorized {
                let adjustPrivacyController = UIAlertController(title: "Denied Access to Photos", message: "Please allow Photo Notes permission to use the camera.", preferredStyle: .alert)
                
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString),
                    UIApplication.shared.canOpenURL(settingsUrl)
                {
                    let actionSettings = UIAlertAction(title: "Open Settings", style: .default, handler: { (_) in
                        UIApplication.shared.open(settingsUrl) { (success) in
                            #if DEBUG
                            print("Settings opened: \(success)")
                            #endif
                        }
                    })
                    adjustPrivacyController.addAction(actionSettings)
                }
                
                let actionDismiss = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
                
                adjustPrivacyController.addAction(actionDismiss)
                present(adjustPrivacyController, animated: true, completion: nil)
            } else {
                presentPhotoGrabViewController()
            }
        }
    }
    
    //MARK: - Table View Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            photosFromLibrary()
        } else if indexPath.section == 2 {
            if indexPath.row == 0 {
                let str_URL = "https://itunes.apple.com/us/app/photo-notes-add-context-to-your-photos/id1021742238?mt=8"
                UIApplication.shared.open(URL(string: str_URL)!, options: [UIApplication.OpenExternalURLOptionsKey.universalLinksOnly : false] , completionHandler: nil)
            } else if indexPath.row == 1 {
                let vc = SFSafariViewController(url: URL(string: "https://www.twitter.com/beDevCurt")!)
                vc.delegate = self
                present(vc, animated: true, completion: nil)
            } else {
                if MFMailComposeViewController.canSendMail() {
                    let vc = MFMailComposeViewController()
                    vc.mailComposeDelegate = self
                    vc.modalPresentationStyle = .pageSheet
                    vc.setToRecipients(["bedevcurt@gmail.com"])
                    vc.setSubject("Photo Notes Support")
                    vc.setMessageBody("Hey Curt!", isHTML: false)
                    present(vc, animated: true, completion: nil)
                }
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //MARK: - Safari and Mail Delegates
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        if result == .cancelled || result == .sent {
            dismiss(animated: true, completion: nil)
        } else if result == .failed {
            dismiss(animated: true, completion: nil)
            
            let alert = UIAlertController(title: "Email Failed", message: "The message failed to send.  Please try again or email me at bedevcurt@gmail.com direct from your Mail app", preferredStyle: .alert)
            let dismiss = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alert.addAction(dismiss)
            present(alert, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = .white
    }

}
