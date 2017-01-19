//
//  AppDelegate.m
//  Unroll2
//
//  Created by Curt on 4/12/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import "CJMAppDelegate.h"
#import "CJMServices.h"
#import "CJMAListViewController.h"


#define kQuickNoteAction @"com.Desdinova.Unroll2.QuickNote"
#define kCameraAction @"com.Desdinova.Unroll2.OpenCamera"

@interface CJMAppDelegate ()

@property (nonatomic, strong) NSDictionary *launchDic;

@end

@implementation CJMAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"HasLaunchedOnce"]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HasLaunchedOnce"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    NSLog(@"application didFinishLaunchingWithOptions called");
    BOOL launchedFromShortCut = NO;
//    var launchedFromShortCut = false
    self.launchDic = launchOptions;
    
    if ([application respondsToSelector:@selector(setShortcutItems:)]) {
        if ([launchOptions objectForKey:UIApplicationLaunchOptionsShortcutItemKey]) {
            UIApplicationShortcutItem *shortcutItem = [launchOptions objectForKey:UIApplicationLaunchOptionsShortcutItemKey];
            launchedFromShortCut = shortcutItem ? YES : NO;
            [self handleShortCutItem:shortcutItem];
        }
    }
    /*Check for ShortCutItem
    if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsShortcutItemKey] as? UIApplicationShortcutItem {
        launchedFromShortCut = true
        handleShortCutItem(shortcutItem)
    }
     */
    
    
#ifdef DEBUG
    [[CJMServices sharedInstance] beginReportingMemoryToConsoleWithInterval:5.f];
#endif

    
    //Return false incase application was launched from shorcut to prevent
    //application(_:performActionForShortcutItem:completionHandler:) from being called
    return !launchedFromShortCut;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    [[CJMAlbumManager sharedInstance] save];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [[CJMAlbumManager sharedInstance] save];
    [[CJMServices sharedInstance] endReportingMemoryToConsole];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
#ifdef DEBUG
    [[CJMServices sharedInstance] beginReportingMemoryToConsoleWithInterval:5.f];
#endif
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    UIApplicationShortcutItem *shortcutItem = [self.launchDic objectForKey:UIApplicationLaunchOptionsShortcutItemKey];
    
    if ([application respondsToSelector:@selector(setShortcutItems:)] && shortcutItem != nil) {
        [self handleShortCutItem:shortcutItem];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [[CJMAlbumManager sharedInstance] save];
}

// implementing shortcut
- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL succeeded))completionHandler {
    BOOL handledShortcut = [self handleShortCutItem:shortcutItem];
    
    completionHandler(handledShortcut);
}

- (BOOL)handleShortCutItem:(UIApplicationShortcutItem *)shortcutItem {
    BOOL handled = NO;
//    var handled = false
    
    NSString *shortcutType = shortcutItem.type;
    
    if (shortcutType) {
        UINavigationController *rootNavController = (UINavigationController *)self.window.rootViewController;
        CJMAListViewController *rootViewController = (CJMAListViewController *)rootNavController.viewControllers.firstObject;
        [rootNavController popToRootViewControllerAnimated:YES];
        
        if ([shortcutType isEqualToString:kQuickNoteAction]) {
            [rootViewController performSegueWithIdentifier:@"ViewQuickNote" sender:nil];
            handled = YES;
        } else if ([shortcutType isEqualToString:kCameraAction]) {
            [rootViewController takePhoto];
            handled = YES;
        }
    }
    
    return handled;
}


@end
