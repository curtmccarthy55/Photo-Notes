//
//  PHNConfig.swift
//  Unroll2
//
//  Created by Curtis McCarthy on 9/13/20.
//  Copyright © 2020 Bluewraith. All rights reserved.
//

import Foundation
import UIKit

/* --- Global Strings --- */
/// End file path for the Photo Notes collection.
let PHN_ALBUMS_FILE = "Unroll.plist"
/// End file path for the Photo Notes user information.
let PHN_USER_FILE = "PHNUser.plist"

public enum Environment {
    case development
    case staging
    case production
}

public let appEnvironment: Environment = .development

//extension UINavigationController {
//    open override var preferredStatusBarStyle: UIStatusBarStyle {
//      return topViewController?.preferredStatusBarStyle ?? .default
//   }
//}
