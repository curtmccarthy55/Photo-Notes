//
//  AppDelegate.swift
//  Unroll2
//
//  Created by Curtis McCarthy on 8/5/19.
//  Copyright © 2019 Blue Evolutions. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics

let kQuickNoteAction = "com.Desdinova.Unroll2.QuickNote"
let kCameraAction = "com.Desdinova.Unroll2.OpenCamera"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var launchDic: [UIApplication.LaunchOptionsKey: Any]?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        PHNUser.current
        Fabric.with([Crashlytics.self])
        
        if UserDefaults.standard.bool(forKey: "HasLaunchedOnce") != true {
            UserDefaults.standard.set(true, forKey: "HasLaunchedOnce")
            UserDefaults.standard.synchronize()
        } else  {
            let user = PHNFileSerializer.
        }
        
        var launchedFromShortCut = false
        launchDic = launchOptions
        
//        if application.responds(to: #selector(setShortcutItems)) {
        if let item = launchOptions?[UIApplication.LaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            launchedFromShortCut = true
            handleShortcutItem(item)
        }
        
        #if DEBUG
//        PHNServices.sharedInstance.beginReportingMemoryToConsole(withInterval: 5.0)
        #endif
        
        //Return false incase application was launched from shorcut to prevent application(_:performActionForShortcutItem:completionHandler:) from being called
        return !launchedFromShortCut
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
        PHNServices.sharedInstance.endReportingMemoryToConsole()
        #endif
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        
        #if DEBUG
        PHNServices.sharedInstance.beginReportingMemoryToConsole(withInterval: 5.0)
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
    
    func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        var handled = false
        var shortcutType = shortcutItem.type
        
        if shortcutType != nil {
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
        }
        
        return handled
    }
}
