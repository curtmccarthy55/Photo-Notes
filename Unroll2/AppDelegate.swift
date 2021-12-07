//
//  AppDelegate.swift
//  Unroll2
//
//  Created by Curtis McCarthy on 8/5/19.
//  Copyright © 2019 Blue Evolutions. All rights reserved.
//

import UIKit

let kQuickNoteAction = "com.Desdinova.Unroll2.QuickNote"
let kCameraAction = "com.Desdinova.Unroll2.OpenCamera"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var launchDic: [UIApplication.LaunchOptionsKey: Any]?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//        PHNUser.current.prepareDefaults()
        
        if UserDefaults.standard.bool(forKey: "HasLaunchedOnce") != true {
            UserDefaults.standard.set(true, forKey: "HasLaunchedOnce")
            UserDefaults.standard.synchronize()
        }
        
        var launchedFromShortCut = false
        launchDic = launchOptions
        
        if let item = launchOptions?[UIApplication.LaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            launchedFromShortCut = true
            handleShortcutItem(item)
        }
        
        customizeNavigationControllerAppearances()
        
        #if DEBUG
//        PHNServices.shared.beginReportingMemoryToConsole(withInterval: 5.0)
        #endif
        
        //Return false incase application was launched from shorcut to prevent application(_:performActionForShortcutItem:completionHandler:) from being called
        return !launchedFromShortCut
    }
    
    func customizeNavigationControllerAppearances() {
//        let navVC = window?.rootViewController as! UINavigationController
//        let photoNotesBlue = UIColor(red: 60.0/255.0, //0.23
//                                     green: 128.0/255.0, //0.50
//                                      blue: 194.0/255.0, //0.76
//                                     alpha: 1.0)
        
        // NavigationBar appearance
        UINavigationBar.appearance().barStyle = .default
        UINavigationBar.appearance().isTranslucent = true
        UINavigationBar.appearance().prefersLargeTitles = true
//        UINavigationBar.appearance().tintColor = .white
        
        // Toolbar appearance
        UIToolbar.appearance().barStyle = .default
        UIToolbar.appearance().isHidden = false
        UIToolbar.appearance().isTranslucent = true
        
        // SearchBar appearance
        // For some reason, barTintColor and backgroundColor need to be set together when trying to make the search bar containing view a dynamic color, otherwise there ends up being a visible rect tight around the search bar text field.
        if #available(iOS 13.0, *) {
            UISearchBar.appearance().barTintColor = .systemGray6
            UISearchBar.appearance().backgroundColor = .systemGray6
            UISearchBar.appearance().tintColor = .label
            UISearchBar.appearance().searchTextField.backgroundColor = .systemGray3
        }
        
        /*
        if #available(iOS 13, *) {
            let normalBarButtonItemAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.label //photoNotesBlue
            ]
            let disabledBarButtonItemAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.gray
            ]
            let highlightedBarButtonItemAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.lightGray
            ]
            
            let barButtonItemAppearance = UIBarButtonItemAppearance()
            barButtonItemAppearance.normal.titleTextAttributes = normalBarButtonItemAttributes
            barButtonItemAppearance.disabled.titleTextAttributes = disabledBarButtonItemAttributes
            barButtonItemAppearance.highlighted.titleTextAttributes = highlightedBarButtonItemAttributes
            
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithDefaultBackground()
            navBarAppearance.buttonAppearance = barButtonItemAppearance
            navBarAppearance.backButtonAppearance = barButtonItemAppearance
            
            UINavigationBar.appearance().standardAppearance = navBarAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        } else {
            
        }
         */
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        
        PHNAlbumManager.sharedInstance.save()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        PHNAlbumManager.sharedInstance.save()
        launchDic = nil
        #if DEBUG
        PHNServices.shared.endReportingMemoryToConsole()
        #endif
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        
        #if DEBUG
        PHNServices.shared.beginReportingMemoryToConsole(withInterval: 5.0)
        #endif
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
//        if application.responds(to: #selector(setShortcutItems)) {
        if let shortcutItem = launchDic?[UIApplication.LaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            handleShortcutItem(shortcutItem)
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        PHNAlbumManager.sharedInstance.save()
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        let handledShortcut = handleShortcutItem(shortcutItem)
        
        completionHandler(handledShortcut)
    }
    
    @discardableResult
    /// Process a received `UIApplicationShortcutItem`, preparing any appropriate segues.
    /// - Parameter shortcutItem: The application shortcut item initiated by the user.
    /// - Returns: Boolean indicating if a segue is prepared.
    func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        var handled = false
        let shortcutType = shortcutItem.type
        
        let rootNavController = window?.rootViewController as! UINavigationController
        let rootViewController = rootNavController.viewControllers.first as! PHNAlbumsTableViewController
        rootNavController.popToRootViewController(animated: true)
        
        if shortcutType == kQuickNoteAction {
            rootViewController.performSegue(withIdentifier: "ViewQuickNote", sender: nil)
            handled = true
        } else if shortcutType == kCameraAction {
            rootViewController.openCamera()
            handled = true
        }
        
        return handled
    }
}
