//
//  PHNFullImageViewController.swift
//  Unroll2
//
//  Created by Curtis McCarthy on 7/18/19.
//  Copyright © 2019 Bluewraith. All rights reserved.
//

import UIKit
import Photos

protocol PHNFullImageViewControllerDelegate: class {
    // These had all previously been optional.  Determine which ones are actually optional (i.e. not implemented in classes that conform to this protocol) and create default implementations in a protocol extension.
    func updateBarsHidden(_ setting: Bool)
    func makeHomeIndicatorVisible(_ visible: Bool)
    func viewController(_ currentVC: PHNFullImageViewController, deletedImageAtIndex imageIndex: Int)
    func photoIsFavorited(_ isFavorited: Bool)
}

// This extension only necessary because of FullImageVC needing a delegate, and PHNAlbumsTableVC having to fulfill that.  Figure out how to change this circumstance.
extension PHNFullImageViewControllerDelegate {
    func updateBarsHidden(_ setting: Bool) {}
    func makeHomeIndicatorVisible(_ visible: Bool) {}
    func viewController(_ currentVC: PHNFullImageViewController, deletedImageAtIndex imageIndex: Int) {}
    func photoIsFavorited(_ isFavorited: Bool) {}
}

class PHNFullImageViewController: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate, UITextViewDelegate {
    
    //MARK: - Properties
    var albumName: String?
    var index: Int? // previously NSInteger
    weak var delegate: PHNFullImageViewControllerDelegate?
    var barsVisible: Bool?
    var imageIsFavorite: Bool?
    var isQuickNote: Bool?
    var noteOpacity: CGFloat?
    var userColor: UIColor?
    var userColorTag: Int? // previously NSNumber
    
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var imageView: UIImageView!
    private var fullImage: UIImage?
    private var photoNote: PhotoNote?
    
    //MARK: ImageView Constraints
    @IBOutlet private weak var topConstraint: NSLayoutConstraint!
    @IBOutlet private weak var leftConstraint: NSLayoutConstraint!
    @IBOutlet private weak var rightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var bottomConstraint: NSLayoutConstraint!
    
    //MARK: Gesture Recognizers
    @IBOutlet private weak var oneTap: UITapGestureRecognizer!
    @IBOutlet private weak var twoTap: UITapGestureRecognizer!
    
    //MARK: Note View and Subviews
    @IBOutlet private weak var noteSection: UIView!
    @IBOutlet private weak var noteTitle: UITextField!
    @IBOutlet private weak var noteEntry: UITextView!
    @IBOutlet private weak var photoLocAndDate: UILabel!
    @IBOutlet private weak var seeNoteButton: UIButton!
    @IBOutlet private weak var editNoteButton: UIButton!
    // Note View Dynamic Constraints
    @IBOutlet private var noteSectionDown: NSLayoutConstraint!
    @IBOutlet private var noteSectionUp: NSLayoutConstraint!
    
    //MARK: Functionality Variables
    private var lastZoomScale: CGFloat?
    private var initialZoomScale: CGFloat?
    private var favoriteChanged: Bool?
    private var displayingNote: Bool?
    private var noteHidden: Bool?
    
    //MARK: - Scene Set Up
    
    override var prefersStatusBarHidden: Bool {
        print("fullImageVC prefersStatusBarHidden called.")
        if barsVisible == false {
            return true
        }
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver( self,
                                      selector: #selector(showBars),
                                          name: NSNotification.Name(rawValue: "ImageShowBars"),
                                        object: nil)
        NotificationCenter.default.addObserver( self,
                                      selector: #selector(hideBars),
                                          name: NSNotification.Name(rawValue: "ImageHideBars"),
                                        object: nil)
        
        // This line prevents the image from jumping around when nav bars are hidden/shown.
        scrollView.contentInsetAdjustmentBehavior = .never
        
        displayingNote = false
        if albumName == nil {
            albumName = "Favorites"
            index = 0
        }
        prepareWithAlbumNamed(albumName!, andIndex: index!)
        PHNServices.sharedInstance.fetchImage(photoNote: photoNote!) { [weak self] (fetchedImage) in
            self?.fullImage = fetchedImage
        }
        
        oneTap.require(toFail: twoTap)
        
        // Following lines moved from viewWillAppear.
        noteSection.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: noteOpacity!)
        
        imageView.image = (fullImage != nil) ? fullImage : UIImage(named: "InAppIcon")
        imageView.accessibilityIgnoresInvertColors = true
        noteSection.accessibilityIgnoresInvertColors = true
        scrollView.accessibilityIgnoresInvertColors = true
        scrollView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.prefersLargeTitles = false
        if isQuickNote != nil, !isQuickNote! {
            delegate?.makeHomeIndicatorVisible(true)
        }
        
        updateZoom()
        favoriteChanged = photoNote!.photoFavorited
        noteTitle.text = photoNote!.photoTitle
        noteTitle.textColor = .white
        noteTitle.adjustsFontSizeToFitWidth = true
        if noteTitle.text == "No Title Created " {
            noteTitle.text = nil
        }
        noteEntry.text = photoNote!.photoNote
        noteEntry.isSelectable = false
        noteEntry.textColor = .white
        noteEntry.alpha = 0.0
        photoLocAndDate.alpha = 0.0
        
        if let creationDate = photoNote!.photoCreationDate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .full
            dateFormatter.timeStyle = .none
            photoLocAndDate.isHidden = false
            
            if isQuickNote != nil, isQuickNote! {
                photoLocAndDate.text = "Note edited \(dateFormatter.string(from: creationDate))"
            } else {
                photoLocAndDate.text = "Photo taken \(dateFormatter.string(from: creationDate))"
            }
        } else {
            photoLocAndDate.isHidden = true
        }
        initialZoomScale = scrollView.zoomScale
        
        updateForBarVisibility(visible: barsVisible!, animated: false)
        if barsVisible != nil, !barsVisible! {
            noteSection.isHidden = false
            noteHidden = false
        }
        updateConstraints()
        
        if isQuickNote != nil, !isQuickNote! {
            delegate?.photoIsFavorited(photoNote!.photoFavorited)
        }
        
        if fullImage == nil {
            scrollView.backgroundColor = .black
        }
        if isQuickNote != nil, isQuickNote! {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Clear",
                                                                style: .done,
                                                               target: self,
                                                               action: #selector(clearNote))
            oneTap.isEnabled = false
            scrollView.backgroundColor = .black // fullImage == nil ? userColor : .black
            if (userColorTag! != 5) && (userColorTag! != 7) {
                navigationController?.navigationBar.barStyle = .black
                navigationController?.navigationBar.tintColor = .white
                navigationController?.toolbar.tintColor = .white
                navigationController?.navigationBar.titleTextAttributes = [ NSAttributedString.Key.foregroundColor : UIColor.white ]
            } else {
                navigationController?.navigationBar.barStyle = .default
                navigationController?.navigationBar.tintColor = .black
                navigationController?.toolbar.tintColor = .black
                navigationController?.navigationBar.titleTextAttributes = [ NSAttributedString.Key.foregroundColor : UIColor.black ]
            }
            navigationController?.navigationBar.barTintColor = userColor
            navigationController?.toolbar.barTintColor = userColor
            
            if isQuickNote != nil, isQuickNote! {
                navigationController?.setToolbarHidden(true, animated: false)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateZoom()
        
        if isQuickNote != nil, isQuickNote! {
            shiftNote(nil)
        }
    }
    
    func prepareWithAlbumNamed(_ name: String, andIndex index: Int) {
        guard let image = PHNAlbumManager.sharedInstance.albumWithName(name, returnImageAtIndex: index) else {
            fatalError("An error occurred: no album was returned from the given album name and index!")
            return
        }
        self.index = index
        photoNote = image
        imageIsFavorite = image.photoFavorited
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if displayingNote != nil, displayingNote! {
            shiftNote(nil)
        }
        if seeNoteButton.titleLabel?.text == "Dismiss" {
            handleNoteSectionDismissal()
        }
        
        updateZoom()
        
        if favoriteChanged != nil, favoriteChanged! == photoNote!.photoFavorited {
            handleFavoriteDidChange()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func handleFavoriteDidChange() {
        if favoriteChanged != nil, favoriteChanged! == false {
            photoNote!.photoFavorited = false
            PHNAlbumManager.sharedInstance.favPhotosAlbum?.remove(photoNote!)
            if let favAlbum = PHNAlbumManager.sharedInstance.favPhotosAlbum,
                photoNote!.isFavoritePreview && favAlbum.albumPhotos.count > 0 {
                let newThumbImage = favAlbum.albumPhotos[0]
                PHNAlbumManager.sharedInstance.albumWithName("Favorites", createPreviewFromImage: newThumbImage)
            }
        } else {
            photoNote!.photoFavorited = true
            PHNAlbumManager.sharedInstance.favPhotosAlbum?.add(photoNote!)
            if photoNote!.originalAlbum == nil && albumName != "Favorites" {
                photoNote!.originalAlbum = albumName
            }
        }
        PHNAlbumManager.sharedInstance.checkFavoriteCount()
        PHNAlbumManager.sharedInstance.save()
        
        if let favAlbum = PHNAlbumManager.sharedInstance.favPhotosAlbum,
            albumName == "Favorites" && favAlbum.albumPhotos.count < 1 {
            guard let array = navigationController?.viewControllers else {
                dismiss(animated: true, completion: nil)
                return
            }
            navigationController?.popToViewController(array[0], animated: true)
        }
    }
    
    //MARK: - ScrollView Zoom Handling
    
    // Update zoom scale and constraints.
    // It will also animate because willAnimateRotationToInterfaceOrientation is called from within the animation block.
    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        super.willAnimateRotation(to: toInterfaceOrientation, duration: duration)
        
        updateZoom()
        initialZoomScale = scrollView.zoomScale
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateConstraints()
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        scrollView.isScrollEnabled = (initialZoomScale! < scrollView.zoomScale) ? true : false
    }
    
    func updateConstraints() {
        let imageWidth = imageView.image!.size.width
        let imageHeight = imageView.image!.size.height
        
        let viewWidth = view.bounds.size.width
        let viewHeight = view.bounds.size.height
        
        // Center image if it is smaller than the screen.
        var horizontalPadding = (viewWidth - scrollView.zoomScale * imageWidth) / 2
        if horizontalPadding < 0 {
            horizontalPadding = 0
        }
        
        var verticalPadding = (viewHeight - scrollView.zoomScale * imageHeight) / 2
        if verticalPadding < 0 {
            verticalPadding = 0
        }
        
        leftConstraint.constant = horizontalPadding
        rightConstraint.constant = horizontalPadding
        
        topConstraint.constant = verticalPadding
        bottomConstraint.constant = verticalPadding
        
        // Makes zoom out animation smooth and starting from the center point rather than (0, 0)
        view.layoutIfNeeded()
    }
    
    // Zoom to show as much image as possible unless image is smaller than screen.
    func updateZoom() {
        var minZoom = min(view.bounds.size.width / imageView.image!.size.width,
                          view.bounds.size.height / imageView.image!.size.height)
        if minZoom > 1 { minZoom = 1 }
        scrollView.minimumZoomScale = minZoom
        
        // Force scrollViewDidZoom to fire if zoom did not change
        if minZoom == lastZoomScale { minZoom += 0.00001 }
        
        scrollView.zoomScale = minZoom
        lastZoomScale = scrollView.zoomScale
//        lastZoomScale = scrollView.zoomScale = minZoom
        
        minZoom -= 0.00001 // TODO see if we can remove this +/- tweak.  In place to make sure scrollView content corrected itself, but probably shouldn't be necessary.
        scrollView.zoomScale = minZoom
//        scrollView.zoomScale = minZoom -= 0.00001
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    //MARK: - Note Shift
    
    //first button press: Slide the note section up so it touches the bottom of the navbar
    //second button press: Slide the note section back down to just above the toolbar
    @IBAction func shiftNote(_ sender: Any?) {
        if displayingNote != nil, displayingNote! == false {
            noteTitle.text = photoNote!.photoTitle
            
            // Display the note section
            displayingNote = true
            noteSectionUp.isActive = true
            noteSectionDown.isActive = false
            noteSection.setNeedsUpdateConstraints()
            
            UIView.animate(withDuration: 0.25) { [weak self] in
                self?.noteSection.superview?.layoutIfNeeded()
                self?.editNoteButton.isHidden = false
                self?.seeNoteButton.setTitle("Dismiss", for: .normal)
                self?.editNoteButton.setTitle("Edit", for: .normal)
                
                self?.noteEntry.alpha = 1.0
                self?.photoLocAndDate.alpha = 1.0
            }
        } else {
            // Dismiss the note section
            displayingNote = false
            noteSectionUp.isActive = false
            noteSectionDown.isActive = true
            noteSection.setNeedsUpdateConstraints()
            handleNoteSectionDismissal()
        }
    }
    
    func handleNoteSectionDismissal() {
        if editNoteButton.titleLabel?.text == "Done" {
            enableEdit(self)
        }
        if noteTitle.text == "No Title Created " {
            noteTitle.text = ""
        }
        
        UIView.animate(withDuration: 0.25) { [weak self] in
            self?.noteSection.superview?.layoutIfNeeded()
            if self?.barsVisible == false {
                self?.editNoteButton.setTitle("Hide", for: .normal)
                self?.editNoteButton.isHidden = false
            } else {
                self?.editNoteButton.isHidden = true
            }
            
            self?.seeNoteButton.setTitle("See Note", for: .normal)
            self?.noteEntry.alpha = 0.0
            self?.photoLocAndDate.alpha = 0.0
        }
    }
    
    @IBAction func dismissQuickNote(_ sender: Any?) {
        if seeNoteButton.titleLabel?.text == "Dismiss" {
            handleNoteSectionDismissal()
        }
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    //MARK: - Navigation Bar Adjustments
    
    @objc func hideBars() {
        barsVisible = false
        editNoteButton.setTitle("Hide", for: .normal)
        editNoteButton.isHidden = false
    }
    
    @objc func showBars() {
        barsVisible = true
        editNoteButton.setTitle("Edit", for: .normal)
        editNoteButton.isHidden = true
    }
    
    func updateForBarVisibility(visible: Bool, animated: Bool) {
        // if called from viewWillAppear: animated == false, else animated == true
        let duration = 0.0 //animated ? 0.2 : 0.0
        if visible {
            if isQuickNote == nil || isQuickNote == false {
                delegate?.makeHomeIndicatorVisible(true)
            }
            UIView.animate(withDuration: duration) { [unowned self] in
                // Toggle bars
                self.navigationController?.setNavigationBarHidden(false, animated: true)
                self.navigationController?.setToolbarHidden(false, animated: true)
                
                // Update not appearance.
                self.scrollView.backgroundColor = .groupTableViewBackground
                self.noteSection.isHidden = false
                self.noteHidden = false
                self.editNoteButton.setTitle("Edit", for: .normal)
                self.editNoteButton.isHidden = true
            }
        } else {
            UIView.animate(withDuration: duration) { [unowned self] in
                // Toggle bars
                self.navigationController?.setNavigationBarHidden(true, animated: true)
                self.navigationController?.setToolbarHidden(true, animated: true)
                
                // Update note appearance
                self.scrollView.backgroundColor = .black
                self.editNoteButton.setTitle("Hide", for: .normal)
                self.editNoteButton.isHidden = false
            }
        }
    }
    
    //MARK: - Buttons and Taps
    
    @objc func clearNote() {
        photoNote?.photoTitle = ""
        photoNote?.photoNote = ""
        noteTitle.text = ""
        noteEntry.text = ""
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        if noteHidden == true {
            return true
        }
        return false
    }
    
    //Implements control states for the note section:
    //Note down, bars visible: button is hidden.
    //Note down, bars hidden: button displays "Hide".  Tapping in this state hides the note section.
    //Note up, text edit disabled: button displays  "Edit".  Tapping enables note section text fields, makes note text field first responsder, changes button text to "Done".
    //Note up, text edit enabled: button displays "Done".  Tapping disables text fields, all fields are checked for text with values being loaded into appropriate photoNote variables.
    @IBAction func enableEdit(_ sender: Any?) {
        if editNoteButton.titleLabel?.text == "Hide" {
            noteSection.isHidden = true
            noteHidden = true
            if isQuickNote == nil || isQuickNote == false {
                delegate?.makeHomeIndicatorVisible(false)
            }
        } else if editNoteButton.titleLabel?.text == "Edit" {
            registerForKeyboardNotifications()
            noteTitle.isEnabled = true
            noteEntry.isEditable = true
            noteEntry.isSelectable = true
            editNoteButton.setTitle("Done", for: .normal)
            noteEntry.becomeFirstResponder()
            noteEntry.selectedRange = NSMakeRange(noteEntry.text.count, 0)
        } else {
            confirmTextFieldNotBlank()
            confirmTextViewNotBlank()
            photoNote?.photoTitle = noteTitle.text
            photoNote?.photoNote = noteEntry.text
            if isQuickNote == true {
                let date = Date()
                photoNote?.photoCreationDate = date
                let formatter = DateFormatter()
                formatter.dateStyle = .full
                formatter.timeStyle = .none
                photoLocAndDate.text = "Note edited \(formatter.string(from: date))"
            }
            noteTitle.isEnabled = false
            noteEntry.isEditable = false
            noteEntry.isSelectable = false
            editNoteButton.setTitle("Edit", for: .normal)
            editNoteButton.sizeToFit()
//            NotificationCenter.default.removeObserver(self)
            NotificationCenter.default.removeObserver( self,
                                                       name: UIResponder.keyboardDidShowNotification,
                                               object: nil)
            NotificationCenter.default.removeObserver( self,
                                                       name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
            
            PHNAlbumManager.sharedInstance.save()
        }
    }
    
    @IBAction func imageViewTapped(_ sender: Any?) {
        #if DEBUG
        print("****IMAGEVIEW TAPPED****")
        #endif
        if isQuickNote == true {
            if let nav = navigationController, nav.navigationBar.isHidden {
                navigationController?.setNavigationBarHidden(false, animated: true)
            } else {
                navigationController?.setNavigationBarHidden(true, animated: true)
            }
        } else {
            let updateBars = !barsVisible!
            barsVisible = updateBars
            updateForBarVisibility(visible: barsVisible!, animated: true)
            delegate?.updateBarsHidden(barsVisible!)
        }
    }
    
    @IBAction func imageViewDoubleTapped(_ gestureRecognizer: UITapGestureRecognizer) {
        if scrollView.zoomScale == initialZoomScale! {
            var centerPoint = gestureRecognizer.location(in: scrollView)
            
            // Current content size back to content scale of 1.0f
            var contentSize: CGSize = .zero
            contentSize.width = scrollView.contentSize.width / initialZoomScale!
            contentSize.height = scrollView.contentSize.height / initialZoomScale!
            
            // Translate the zoom point to relative to the content rect
            centerPoint.x = (centerPoint.x / scrollView.bounds.size.width) * contentSize.width
            centerPoint.y = (centerPoint.y / scrollView.bounds.size.height) * contentSize.height
            
            // Get the size of the region to zoom to
            var zoomSize = CGSize.zero
            zoomSize.width = scrollView.bounds.size.width / (initialZoomScale! * 4.0)
            zoomSize.height = scrollView.bounds.size.height / (initialZoomScale! * 4.0)
            
            // Offset the zoom rect so the actual zoom point is in  the middle of the rectangle.
            var zoomRect = CGRect.zero
            zoomRect.origin.x = centerPoint.x - zoomSize.width / 2.0
            zoomRect.origin.y = centerPoint.y - zoomSize.height / 2.0
            zoomRect.size.width = zoomSize.width
            zoomRect.size.height = zoomSize.height
            
            // Resize
            scrollView.zoom(to: zoomRect, animated: true)
        } else {
            UIView.animate(withDuration: 0.25) { [weak self] in
                self?.updateZoom()
            }
            scrollView.isScrollEnabled = false
        }
    }
    
    //MARK: - Button Responses
    
    func showPopUpMenu() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let setPreviewImage = UIAlertAction(title: "Use For Album List Thumbnail", style: .default) { [unowned self] (_) in
            PHNAlbumManager.sharedInstance.albumWithName(self.albumName!, createPreviewFromImage: self.photoNote!)
            PHNAlbumManager.sharedInstance.save()
            
            let hudView = PHNHudView.hud(inView: self.navigationController!.view,
                                       withType: "Success",
                                       animated: true)
            hudView.text = "Done!"
//            hudView.perform(#selector(removeFromSuperview), with: nil, afterDelay: 1.5)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: { [weak self] in
                hudView.removeFromSuperview()
                self?.navigationController?.view.isUserInteractionEnabled = true
            })
        }
        
        let saveImageAction = UIAlertAction(title: "Save To Camera Roll", style: .default) { [unowned self] (_) in
            UIImageWriteToSavedPhotosAlbum(self.fullImage!, nil, nil, nil)
            
            let hudView = PHNHudView.hud(inView: self.navigationController!.view, withType: "Success", animated: true)
            hudView.text = "Done"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: { [weak self] in
                hudView.removeFromSuperview()
                self?.navigationController?.view.isUserInteractionEnabled = true
            })
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(saveImageAction)
        alert.addAction(setPreviewImage)
        alert.addAction(cancelAction)
        
        alert.popoverPresentationController?.sourceRect = CGRect(x: view.frame.size.width - 27.0, y: view.frame.size.height - 40.0, width: 1.0, height: 1.0)
        alert.popoverPresentationController?.permittedArrowDirections = .down
        alert.popoverPresentationController?.sourceView = view
        
        present(alert, animated: true, completion: nil)
    }
    
    func confirmImageDelete() {
        let albumIsFavorites = albumName == "Favorites"
        let message = albumIsFavorites ? "Delete from all albums or unfavorite?" : "You cannot recover this photo after deleting."
        let alertController = UIAlertController(title: "Delete Photo?",
                                              message: message,
                                       preferredStyle: .actionSheet)
        let saveToPhotosAndDelete = UIAlertAction(title: "Save To Camera Roll And Then Delete", style: .default) { [unowned self] (_) in
            UIImageWriteToSavedPhotosAlbum(self.fullImage!, nil, nil, nil)
            self.favoriteChanged = false
            self.delegate?.photoIsFavorited(false)
            PHNServices.sharedInstance.deleteImageFrom(photoNote: self.photoNote!)
            PHNAlbumManager.sharedInstance.albumWithName(self.albumName!, removeImageWithUUID: self.photoNote!.fileName)
            if albumIsFavorites {
                PHNAlbumManager.sharedInstance.albumWithName(self.photoNote!.originalAlbum!, removeImageWithUUID: self.photoNote!.fileName)
            }
            
            PHNAlbumManager.sharedInstance.checkFavoriteCount()
            PHNAlbumManager.sharedInstance.save()
            
            self.delegate?.viewController(self, deletedImageAtIndex: self.index!)
        }
        
        let deletePhoto = UIAlertAction(title: "Delete Permanently", style: .default) { [unowned self] (_) in
            self.favoriteChanged = false
            self.delegate?.photoIsFavorited(false)
            
            PHNServices.sharedInstance.deleteImageFrom(photoNote: self.photoNote!)
            PHNAlbumManager.sharedInstance.albumWithName(self.albumName!, removeImageWithUUID: self.photoNote!.fileName)
            if albumIsFavorites {
                PHNAlbumManager.sharedInstance.albumWithName(self.photoNote!.originalAlbum!, removeImageWithUUID: self.photoNote!.fileName)
            }
            
            PHNAlbumManager.sharedInstance.checkFavoriteCount()
            PHNAlbumManager.sharedInstance.save()
            self.delegate?.viewController(self, deletedImageAtIndex: self.index!)
        }
        
        let unfavoritePhoto = UIAlertAction(title: "Unfavorite And Remove", style: .default) { [unowned self] (_) in
            self.favoriteChanged = false
            self.delegate?.photoIsFavorited(false)
            PHNAlbumManager.sharedInstance.albumWithName(self.albumName!, removeImageWithUUID: self.photoNote!.fileName)
            self.delegate?.viewController(self, deletedImageAtIndex: self.index!)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(saveToPhotosAndDelete)
        alertController.addAction(deletePhoto)
        if albumIsFavorites { alertController.addAction(unfavoritePhoto) }
        alertController.addAction(cancel)
        
        alertController.popoverPresentationController?.sourceRect = CGRect(x: 26.0, y: view.frame.size.height - 40.0, width: 1.0, height: 1.0)
        alertController.popoverPresentationController?.permittedArrowDirections = .down
        alertController.popoverPresentationController?.sourceView = view
        
        present(alertController, animated: true, completion: nil)
    }
    
    func actionFavorite(_ userFavorited: Bool) {
        favoriteChanged = userFavorited
        
        if albumName == "Favorites" {
            handleFavoriteDidChange()
            delegate?.viewController(self, deletedImageAtIndex: index!)
        }
    }
    
    //MARK: - TextView and TextField Delegate
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "Tap Edit to change the title and note!" {
            textView.text = nil
        }
    }
    
    func confirmTextViewNotBlank() {
        if noteEntry.text.count == 0 {
            noteEntry.text = "Tap Edit to change the title and note!"
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.text == "No Title Created " {
            textField.text = nil
        }
    }
    
    func confirmTextFieldNotBlank() {
        if noteTitle.text?.count == 0 {
            noteTitle.text = "No Title Created "
        }
    }
    
    //MARK: - Keyboard Shift
    
    //Below methods make sure the note section isn't covered by the keyboard.
    func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver( self,
                                      selector: #selector(keyboardWasShown),
                                          name: UIResponder.keyboardDidShowNotification,
                                        object: nil)
        NotificationCenter.default.addObserver( self,
                                      selector: #selector(keyboardWillBeHidden),
                                          name: UIResponder.keyboardWillHideNotification,
                                        object: nil)
    }
    
    @objc func keyboardWasShown(aNotification: Notification) {
        let info = aNotification.userInfo!
        let keyboardSize = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size
        
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize!.height - 20.0, right: 0)
        noteEntry.contentInset = contentInsets
        noteEntry.scrollIndicatorInsets = contentInsets
    }
    
    @objc func keyboardWillBeHidden(aNotification: Notification) {
        let contentInsets = UIEdgeInsets.zero
        noteEntry.contentInset = contentInsets
        noteEntry.scrollIndicatorInsets = contentInsets
    }
}
