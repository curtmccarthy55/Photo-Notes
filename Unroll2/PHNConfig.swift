//
//  PHNConfig.swift
//  Unroll2
//
//  Created by Curtis McCarthy on 9/13/20.
//  Copyright © 2020 Bluewraith. All rights reserved.
//

import Foundation
import UIKit

public enum Environment {
    case development
    case staging
    case production
}

public let appEnvironment: Environment = .development

/// Enumeration to specify theme color (bars, background colors, etc.).
enum NewThemeColor: Equatable {
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
    static func ==(lhs: NewThemeColor, rhs: NewThemeColor) -> Bool {
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

