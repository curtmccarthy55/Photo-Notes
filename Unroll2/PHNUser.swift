//
//  PHNUser.swift
//  Unroll2
//
//  Created by Curtis McCarthy on 9/13/20.
//  Copyright © 2020 Bluewraith. All rights reserved.
//

import Foundation
import UIKit

/// Enumeration to specify theme color (bars, background colors, etc.).
enum NewThemeColor {
    case blue
    case red
    case black
    case purple
    case orange
    case yellow
    case green
    case white
    case custom(CGFloat, CGFloat, CGFloat, CGFloat) // (red, green, blue, alpha values).
    
    enum ColorBrightness {
        case dark
        case light
    }
    
    func determineBrightness(red: CGFloat, green: CGFloat, blue: CGFloat) -> ColorBrightness {
        let average = (red + green + blue) / 3.0
        if average >= 0.55 {
            return .light
        } else {
            return .dark
        }
    }
    
    /// Determines the average brightness of the color based on it's RGB values and returns a float between 0.0 (dark) and 1.0 (light) to indicate this.  A returned value greater than 0.55 is better suited to have dark-tinted navigation items, home indicator, etc, while a returned value lower than 0.55 will be better suited with light-tinted navigation items, home indicator, etc.
    /// - Returns: `CGFloat` representing how dark or bright the color is.
    func colorBrightness() -> ColorBrightness {
        switch self {
        case .blue:
            return determineBrightness(red: 60.0/255.0,
                                     green: 128.0/255.0,
                                      blue: 194.0/255.0)
        case .red:
            return determineBrightness(red: 150.0/255.0,
                                     green: 0,
                                      blue: 23.0/255.0)
                
        case .black:
            return determineBrightness(red: 50.0/255.0,
                                     green: 50.0/255.0,
                                      blue: 50.0/255.0)
                
        case .purple:
            return determineBrightness(red: 130.0/255.0,
                                     green: 0,
                                      blue: 202.0/255.0)
        case .orange:
            return determineBrightness(red: 1.0,
                                     green: 130.0/255.0,
                                      blue: 0)
        case .yellow:
            return determineBrightness(red: 242.0/255.0,
                                     green: 242.0/255.0,
                                      blue: 83.0/255.0)
        case .green:
            return determineBrightness(red: 0,
                                     green: 122.0/255.0,
                                      blue: 39.0/255.0)
        case .white:
            return determineBrightness(red: 1.0,
                                     green: 1.0,
                                      blue: 1.0)
        case .custom(let red, let green, let blue, _):
            return determineBrightness(red: red,
                                     green: green,
                                      blue: blue)
        }
    }
    
    /// Returns the UIColor for this theme.
    /// - Returns: UIColor for this theme.
    func colorForTheme() -> UIColor {
        var color: UIColor
        switch self {
        case .blue:
            color = UIColor(red: 60.0/255.0, //0.23
                          green: 128.0/255.0, //0.50
                           blue: 194.0/255.0, //0.76
                          alpha: 1.0)
//            selectedTag = 0
        case .red:
            color = UIColor(red: 150.0/255.0,
                          green: 0,
                           blue: 23.0/255.0,
                          alpha: 1.0)
//            selectedTag = 1
        case .black:
            color = UIColor(red: 50.0/255.0,
                          green: 50.0/255.0,
                           blue: 50.0/255.0,
                          alpha: 1.0)
//            selectedTag = 2
        case .purple:
            color = UIColor(red: 130.0/255.0,
                          green: 0,
                           blue: 202.0/255.0,
                          alpha: 1.0)
            //selectedTag = 3
        case .orange:
            color = UIColor(red: 1.0,
                          green: 130.0/255.0,
                           blue: 0,
                          alpha: 1.0)
//            selectedTag = 4
        case .yellow:
            color = UIColor(red: 242.0/255.0,
                          green: 242.0/255.0,
                           blue: 83.0/255.0,
                          alpha: 1.0)
//            selectedTag = 5
        case .green:
            color = UIColor(red: 0,
                          green: 122.0/255.0,
                           blue: 39.0/255.0,
                          alpha: 1.0)
//            selectedTag = 6
        case .white:
            color = UIColor(red: 1.0,
                          green: 1.0,
                           blue: 1.0,
                          alpha: 1.0)
//            selectedTag = 7
        case .custom(let red, let green, let blue, let alpha):
            color = UIColor(red: red,
                          green: green,
                           blue: blue,
                          alpha: alpha)
        }
        
        return color
    }
    
    /*
    func selectedColorWithTag(_ tag: Int) -> NSDictionary {
        var dictionary = NSMutableDictionary()
        var red, green, blue: NSNumber
        var selectedTag: NSNumber
        
        switch tag {
        case ThemeColor.kPhotoNotesBlue.rawValue:
            red = NSNumber(value: 60.0/255.0)
            green = NSNumber(value: 128.0/255.0)
            blue = NSNumber(value: 194.0/255.0)
            selectedTag = 0
        case ThemeColor.kPhotoNotesRed.rawValue:
            red = NSNumber(value: 150.0/255.0)     // 207/255 //-> 150/255.0
            green = NSNumber(value: 0)   // 54/255  //-> 0/255.0
            blue = NSNumber(value: 23.0/255.0)     // 51/255  //-> 23/255.0
            selectedTag = 1
        case ThemeColor.kPhotoNotesBlack.rawValue:
            red = NSNumber(value: 50.0/255.0)
            green = NSNumber(value: 50.0/255.0)
            blue = NSNumber(value: 50.0/255.0)
            selectedTag = 2
        case ThemeColor.kPhotoNotesPurple.rawValue:
            red = NSNumber(value: 130.0/255)
            green = NSNumber(value: 0)
            blue = NSNumber(value: 202.0/255.0)
            selectedTag = 3
        case ThemeColor.kPhotoNotesOrange.rawValue:
            red = NSNumber(value: 255.0/255.0)
            green = NSNumber(value: 130.0/255.0)
            blue = NSNumber(value: 0)
            selectedTag = 4
        case ThemeColor.kPhotoNotesYellow.rawValue:
            red = NSNumber(value: 242.0/255.0)
            green = NSNumber(value: 242.0/255.0)
            blue = NSNumber(value: 83.0/255.0)
            selectedTag = 5
        case ThemeColor.kPhotoNotesGreen.rawValue:
            red = NSNumber(value: 0)
            green = NSNumber(value: 122.0/255.0)
            blue = NSNumber(value: 39.0/255.0)
            selectedTag = 6
        case ThemeColor.kPhotoNotesWhite.rawValue:
            red = NSNumber(value: 1.0)
            green = NSNumber(value: 1.0)
            blue = NSNumber(value: 1.0)
            selectedTag = 7
        default: // set to PhotoNotesBlue
            red = NSNumber(value: 60.0/255.0)
            green = NSNumber(value: 128.0/255.0)
            blue = NSNumber(value: 194.0/255.0)
            selectedTag = 0
        }
        
        dictionary.setValue(red, forKey: "PhotoNotesRed")
        dictionary.setValue(green, forKey: "PhotoNotesGreen")
        dictionary.setValue(blue, forKey: "PhotoNotesBlue")
        dictionary.setValue(selectedTag, forKey: "PhotoNotesColorTag")
        
        return dictionary
    }
    */
}
/*
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
 */

/// Type to manage user set preferences and settings (e.g. app color, note opacity, etc.).
class PHNUser {
    /// Singleton for `PHNUser`.
    static let current = PHNUser()
    private init() {}
    
    // MARK: - User Preferences
    
    /// User's preferred note opacity. Used as alpha value for the note section.
    var preferredNoteOpacity: CGFloat = 0.75
    /// Users preferred color for container views, bars, etc.  Defaults to light blue shade.
    var preferredThemeColor: NewThemeColor = .blue
    
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
