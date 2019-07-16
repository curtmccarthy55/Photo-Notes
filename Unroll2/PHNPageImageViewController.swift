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
    var initialIndex: Int // was NSInteger
    var albumName: String
//    var pageViewController: UIPageViewController  // this shouldn't be necessary...
    var albumCount: Int
    
    //MARK: Private Properties
    private var makeViewsVisible = true
    private var makeHomeVisible = false
    private var noteOpacity: CGFloat
    private var currentIndex: Int // was NSInteger
    
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
    
    //MARK: - Scene Set Up
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = self
        currentIndex = initialIndex
        prefersStatusBarHidden
        setNeedsStatusBarAppearanceUpdate()
        view.backgroundColor = .white
        if let numOpacity = UserDefaults.standard.value(forKey: "noteOpacity") as? NSNumber {
            noteOpacity = numOpacity.floatValue
        } else {
            noteOpacity = 0.75
        }
        
        let fullImageVC = fullImageViewControllerForIndex(initialIndex)
        setViewControllers([fullImageVC], direction: .forward, animated: false, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    //MARK: - UIPageViewController DataSource
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: PHNFullImageViewController) -> UIViewController? {
        let previousIndex = viewController.index - 1
        return fullImageViewControllerForIndex(previousIndex)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: PHNFullImageViewController) -> UIViewController? {
        <#code#>
    }
    /*
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(CJMFullImageViewController *)currentImageVC {
    NSInteger nextIndex = currentImageVC.index + 1;
    return [self fullImageViewControllerForIndex:nextIndex];
}
     */
    
    
    /*
     
 */
    
    /*
//MARK: - Initializers and Scene Set Up (from PDRScope PDRInvoiceViewController)
    init(viewModel: PDRInvoiceViewModel) {
        self.viewModel = viewModel
        estimateDetailRowData = viewModel.estimateDetailRowData()
        super.init(nibName: "PDRInvoiceViewController", bundle: nil)
    }
 */

}
