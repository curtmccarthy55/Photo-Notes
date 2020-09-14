//
//  PHNUser.swift
//  Unroll2
//
//  Created by Curtis McCarthy on 9/13/20.
//  Copyright © 2020 Bluewraith. All rights reserved.
//

import Foundation
import UIKit

/// Type to manage user set preferences and settings (e.g. app color, note opacity, etc.).
class PHNUser {
    /// Singleton for `PHNUser`.
    static let current = PHNUser()
    private init() {}
    
    // MARK: - User Preferences
    
    /// User's preferred note opacity. Used as alpha value for the note section.
    var preferredNoteOpacity: CGFloat = 0.75
    /// Users preferred color for container views, bars, etc.  Defaults to light blue shade.
    var preferredThemeColor: NewThemeColor = .custom(0, 128.0/255.0, 128.0/255.0, 1.0)
    
    /*
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
        
        navigationController?.navigationBar.barTintColor = userColor
        navigationController?.toolbar.barTintColor = userColor
    }
 */
}
