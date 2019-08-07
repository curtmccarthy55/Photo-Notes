//
//  PHNPageImageViewController.swift
//  Unroll2
//
//  Created by Curtis McCarthy on 7/15/19.
//  Copyright © 2019 Bluewraith. All rights reserved.
//

import UIKit

class PHNPageImageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, PHNFullImageViewControllerDelegate {
    
    //MARK: - Properties
    var initialIndex: Int! // was NSInteger
    var albumName: String!
//    var pageViewController: UIPageViewController  // this shouldn't be necessary...
    var albumCount: Int!
    
    //MARK: Private Properties
    private var makeViewsVisible = true
    private var makeHomeVisible = false
    private var noteOpacity: CGFloat!
    private var currentIndex: Int! // was NSInteger
    
    @IBOutlet weak var barButtonFavorite: UIBarButtonItem!
    @IBOutlet weak var barButtonOptions: UIBarButtonItem!
    
    override var prefersStatusBarHidden: Bool {
        if makeViewsVisible == false || traitCollection.verticalSizeClass == .compact {
            #if DEBUG
            print("PageImageVC prefersStatusBarHidden returned true")
            #endif
            return true
        } else {
            #if DEBUG
            print("PageImageVC prefersStatusBarHidden return false")
            #endif
            return false
        }
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        if !makeViewsVisible && !makeHomeVisible { // if bars aren't visible or
            return true
        } else {
            return false
        }
    }
    
    //MARK: - Scene Set Up
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = self
        currentIndex = initialIndex
        prefersStatusBarHidden
        setNeedsStatusBarAppearanceUpdate()
        view.backgroundColor = .white
        if let numOpacity = UserDefaults.standard.value(forKey: "noteOpacity") as? NSNumber {
            noteOpacity = CGFloat(exactly: numOpacity)!
        } else {
            noteOpacity = 0.75
        }
        
        if let fullImageVC = fullImageViewControllerForIndex(initialIndex) {
            setViewControllers([fullImageVC], direction: .forward, animated: false, completion: nil)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    //MARK: - UIPageViewController DataSource
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let imageVC = viewController as? PHNFullImageViewController else {
            //TODO some other error handling?
            return nil
        }
        let previousIndex = imageVC.index! - 1
        return fullImageViewControllerForIndex(previousIndex)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let currentImageVC = viewController as? PHNFullImageViewController else {
            //TODO some other error handling?
            return nil
        }
        let nextIndex = currentImageVC.index! + 1
        return fullImageViewControllerForIndex(nextIndex)
    }
    
    func fullImageViewControllerForIndex(_ index: Int) -> PHNFullImageViewController? {
        if index >= albumCount || index < 0 {
            return nil
        } else {
            currentIndex = index
            let fullImageController = storyboard!.instantiateViewController(withIdentifier: "FullImageVC") as! PHNFullImageViewController
            fullImageController.index = index
            fullImageController.albumName = albumName
            fullImageController.delegate = self
            fullImageController.noteOpacity = noteOpacity
            fullImageController.barsVisible = makeViewsVisible
            
            return fullImageController
        }
    }
    
    //MARK: - UIPageViewControllerDelegate
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            // currentIndex should match the new vc's index.
        } else {
            // currentIndex should match the original vc's index.
        }
    }
    
    //MARK: - NavBar and Toolbar Buttons
    
    @IBAction func favoriteImage(_ sender: UIBarButtonItem) {
        let currentVC = viewControllers![0] as! PHNFullImageViewController
        
        if sender.image == UIImage(named: "WhiteStarEmpty") {
            sender.image = UIImage(named: "WhiteStarFull")
            currentVC.actionFavorite(true)
        } else {
            sender.image = UIImage(named: "WhiteStarEmpty")
            currentVC.actionFavorite(false)
        }
    }
    
    @IBAction func currentPhotoOptions(_ sender: Any) {
        let currentVC = viewControllers![0] as! PHNFullImageViewController
        currentVC.showPopUpMenu()
    }
    
    @IBAction func deleteCurrentPhoto(_ sender: Any) {
        let currentVC = viewControllers![0] as! PHNFullImageViewController
        currentVC.confirmImageDelete()
    }
    
    //MARK: - PHNFUllImageVC Delegate Methods
    
    func updateBarsHidden(_ setting: Bool) {
        makeViewsVisible = setting
        setNeedsStatusBarAppearanceUpdate()
        if makeViewsVisible {
            NotificationCenter.default.post(name: Notification.Name("ImageShowBars"), object: nil)
        } else {
            NotificationCenter.default.post(name: Notification.Name("ImageHideBars"), object: nil)
        }
    }
    
    func makeHomeIndicatorVisible(_ visible: Bool) {
        makeHomeVisible = visible
        setNeedsUpdateOfHomeIndicatorAutoHidden()
    }
    
    /// Deletes the currently displayed image and updates screen based on position in album
    func viewController(_ currentVC: PHNFullImageViewController, deletedImageAtIndex imageIndex: Int) {
        if (albumCount - 1) == 0 {
            navigationController?.popViewController(animated: true)
        } else if (imageIndex + 1) >= albumCount {
            let previousVC = pageViewController(self, viewControllerBefore: currentVC) as! PHNFullImageViewController
            albumCount -= 1
            
            setViewControllers([previousVC], direction: .reverse, animated: true, completion: nil)
        } else {
            let nextVC = pageViewController(self, viewControllerAfter: currentVC) as! PHNFullImageViewController
            nextVC.index = imageIndex
            albumCount -= 1
            
            setViewControllers([nextVC], direction: .forward, animated: true, completion: nil)
        }
    }
    
    func photoIsFavorited(_ isFavorited: Bool) {
        if !isFavorited {
            barButtonFavorite.image = UIImage(named: "WhiteStarEmpty")
        } else {
            barButtonFavorite.image = UIImage(named: "WhiteStarFull")
        }
    }
}
