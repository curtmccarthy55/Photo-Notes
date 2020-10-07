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
    private init() {
        setThemeColor(.red)
    }
    
    // MARK: - User Preferences
    
    /// User's preferred note opacity. Used as alpha value for the note section.
    var preferredNoteOpacity: CGFloat = 0.75
    /// Users preferred color for container views, bars, etc.  Defaults to light blue shade.
    var preferredThemeColor: PHNThemeColor = .blue // .custom(0, 128.0/255.0, 128.0/255.0, 1.0) // .teal
    
    /// Sets the `preferredThemeColor` and accordingly updates the appearance of UINavigationBar and UIToolbar.
    /// - Parameter newTheme: The new `PHNThemeColor`.
    func setThemeColor(_ newTheme: PHNThemeColor) {
        preferredThemeColor = newTheme
        
        let userColor = preferredThemeColor.colorForTheme()
        UINavigationBar.appearance().barTintColor = userColor
        UIToolbar.appearance().barTintColor = userColor
        
        let colorBrightnness = preferredThemeColor.colorBrightness()
        switch colorBrightnness {
        case .light:
            UINavigationBar.appearance().barStyle = .default
            UINavigationBar.appearance().tintColor = .black
            UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.black]
            UIToolbar.appearance().tintColor = .black
        case .dark:
            UINavigationBar.appearance().barStyle = .default
            UINavigationBar.appearance().tintColor = .white
            UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white]
            UIToolbar.appearance().tintColor = .white
        }
    }
}

/// Enumeration to specify theme color (bars, background colors, etc.).
/// - Call instance methods `colorForTheme()` for the UIColor, and `colorBrightness()` for the general brightness of the color to determine tint on overlaid objects, like BarButtons or the Home indicator.
enum PHNThemeColor: Equatable {
    case blue
    case red
    case black
    case purple
    case orange
    case yellow
    case green
    case white
    case custom(CGFloat, CGFloat, CGFloat, CGFloat) // (red, green, blue, alpha values).
    
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
    
    // MARK: Equatable
    static func ==(lhs: PHNThemeColor, rhs: PHNThemeColor) -> Bool {
        switch (lhs, rhs) {
        case (let .custom(r1, g1, b1, a1), let .custom(r2, g2, b2, a2)):
            if r1 == r2 && g1 == g2 && b1 == b2 && a1 == a2 {
                return true
            } else {
                return false
            }
        case (.blue, .blue):
            return true
        case (.red, .red):
            return true
        case (.black, .black):
            return true
        case (.purple, .purple):
            return true
        case (.orange, .orange):
            return true
        case (.yellow, .yellow):
            return true
        case (.green, .green):
            return true
        case (.white, .white):
            return true
        default:
            return false
        }
    }
    
    //MARK: enum ColorBrightness
    /// The general brightness used to describe a specified `ColorTheme`.  Used to determine the tint of objects that will appear over the color, like bar buttons or the home indicator.
    enum ColorBrightness {
        case dark
        case light
    }
    
    /// Determines how bright the passed in color by taking an average of the color values.
    /// - Parameters:
    ///   - red: Red color value.
    ///   - green: Green color value.
    ///   - blue: Blue color value.
    /// - Returns: `ColorBrightness` value, `.light` or `.dark`.
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
}
