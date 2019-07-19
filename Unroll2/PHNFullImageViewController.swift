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
    @IBOutlet private weak var noteSectionDown: NSLayoutConstraint!
    @IBOutlet private weak var noteSectionUp: NSLayoutConstraint!
    
    //MARK: Functionality Variables
    private var lastZoomScale: CGFloat?
    private var initialZoomScale: Float?
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
                                          name: "ImageShowBars",
                                        object: nil)
        NotificationCenter.default.addObserver( self,
                                      selector: #selector(hideBars),
                                          name: "ImageHideBars",
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
        
        //cjm 09/25 nav bar handling
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
                navigationController?.navigationBar.titleTextAttributes = [ NSForegroundColorAttributeName : UIColor.white ]
            } else {
                navigationController?.navigationBar.barStyle = .default
                navigationController?.navigationBar.tintColor = .black
                navigationController?.toolbar.tintColor = .black
                navigationController?.navigationBar.titleTextAttributes = [ NSForegroundColorAttributeName : UIColor.black ]
            }
            navigationController?.navigationBar.barTintColor = userColor
            
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
            guard let array = navigationController?.viewControllers else { dismiss(animated: true, completion: nil) }
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
    
    override func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateConstraints()
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        scrollView.isScrollEnabled = (initialZoomScale! < scrollView.zoomScale) ? true : false
    }
    
    func updateConstraints() {
        let imageWidth: Float = imageView.image!.size.width
        let imageHeight: Float = imageView.image!.size.height
        
        let viewWidth: Float = view.bounds.size.width
        let viewHeight: Float = view.bounds.size.height
        
        // Center image if it is smaller than the screen.
        var horizontalPadding: Float = (viewWidth - scrollView.zoomScale * imageWidth) / 2
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
        let minZoom: Float = min(view.bounds.size.width / imageView.image!.size.width,
                                 view.bounds.size.height / imageView.image!.size.height)
        if minZoom > 1 { minZoom = 1 }
        scrollView.minimumZoomScale = minZoom
        
        // Force scrollViewDidZoom to fire if zoom did not change
        if minZoom == lastZoomScale { minZoom += 0.00001 }
        
        lastZoomScale = scrollView.zoomScale = minZoom
        scrollView.zoomScale = minZoom -= 0.00001 // TODO see if we can remove this +/- tweak.  In place to make sure scrollView content corrected itself, but probably shouldn't be necessary.
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
    
    func hideBars() {
        barsVisible = false
        editNoteButton.setTitle("Hide", for: .normal)
        editNoteButton.isHidden = false
    }
    
    func showBars() {
        barsVisible = true
        editNoteButton.setTitle("Edit", for: .normal)
        editNoteButton.isHidden = true
    }
    
    func updateForBarVisibility(visible: Bool, animated: Bool) {
        
    }
    /*
- (void)updateForBarVisibility:(BOOL)visible animated:(BOOL)animated {
    //if called from viewWillAppear: animated == false, else animated == true
    NSTimeInterval duration = 0.0;//animated ? 0.2 : 0.0;
    if (visible) {
        if (!self.isQuickNote) {
            [self.delegate makeHomeIndicatorVisible:YES];
        }
        [UIView animateWithDuration:duration animations:^{
            //toggleBars
            [self.navigationController setNavigationBarHidden:NO animated:YES];
            [self.navigationController setToolbarHidden:NO animated:YES];

            //update note appearance
            self.scrollView.backgroundColor = [UIColor groupTableViewBackgroundColor];
            [self.noteSection setHidden:NO];
            self.noteHidden = NO;
            [self.editNoteButton setTitle:@"Edit" forState:UIControlStateNormal];
            [self.editNoteButton setHidden:YES];
        }];
    } else if (!visible)  {
        [UIView animateWithDuration:duration animations:^{
            //toggleBars
            [self.navigationController setNavigationBarHidden:YES animated:YES];
            [self.navigationController setToolbarHidden:YES animated:YES];

            //update note appearance
            self.scrollView.backgroundColor = [UIColor blackColor];
            [self.editNoteButton setTitle:@"Hide" forState:UIControlStateNormal];
            [self.editNoteButton setHidden:NO];
        }];
    }
}
 */
    
    func prepareWithAlbumNamed(_ name: String, andIndex index: Int) {
        
    }
    
    
    //- (void)updateForBarVisibility:(BOOL)visible animated:(BOOL)animated {
    func updateForBarVisibility(visible: Bool, animated: Bool) {
        
    }
    
    func clearNote() {
        
    }
}
