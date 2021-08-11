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
class PHNUser: Codable {
    /// Singleton for `PHNUser`.
    static let current = PHNUser()
    private init() {
//        if let user =
        /*
        if let set = fileSerializer.readObjectFromRelativePath(CJMAlbumFileName) as? [PHNPhotoAlbum] {
            #if DEBUG
            print("PHNPhotoAlbums fetched for album manager.")
            #endif
            return set
        }
        return []
*/
    }
    
    /// Prepare user defaults.
    func prepareDefaults() {
        setThemeColor(.blue)
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
    
    //MARK: - Codable
    
    private enum CodingKeys: String, CodingKey {
        case preferredNoteOpacity
        case preferredThemeColor
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(preferredNoteOpacity, forKey: .preferredNoteOpacity)
        try container.encode(preferredThemeColor, forKey: .preferredThemeColor)
    }
    
    required init(from decoder: Decoder) throws {
        let container        = try decoder.container(keyedBy: CodingKeys.self)
        preferredThemeColor  = try container.decode(PHNThemeColor.self, forKey: .preferredThemeColor)
        preferredNoteOpacity = try container.decode(CGFloat.self, forKey: .preferredNoteOpacity)
    }
}

// MARK: -
/// Enumeration to specify theme color (bars, background colors, etc.).
/// - Call instance methods `colorForTheme()` for the UIColor, and `colorBrightness()` for the general brightness of the color to determine tint on overlaid objects, like BarButtons or the Home indicator.
enum PHNThemeColor: Codable, Equatable {
    case blue
    case red
    case black
    case purple
    case orange
    case yellow
    case green
    case white
    case custom(red: Float, green: Float, blue: Float, alpha: Float = 1.0)
    
    private enum CodingKeys: CodingKey {
        case blue, red, black, purple, orange, yellow, green, white, custom
    }
    
    /*
     • For cases without associated values, we don't need to decode anything, only assign the case to self.
     • For cases with one associated value, we try to decode that value.
     • For cases with multiple associated values, we need to get the nestedUnkeyedContainer from the decoder, then decode the values one by one in the correct order.
     • If we hit the default case, we will throw a DecodingError including the codingPath for debugging.
     */
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // We get the KeyedDecodingContainer from the decoder and extract its first key. As we encoded an enum, we only expect to have one top level key. Then we switch on the key to initialize the enum.
        let key = container.allKeys.first
        
        switch key {
        case .blue:
            self = .blue
        case .red:
            self = .red
        case .black:
            self = .red
        case .purple:
            self = .purple
        case .orange:
            self = .orange
        case .yellow:
            self = .yellow
        case .green:
            self = .green
        case .white:
            self = .white
        case .custom:
            var nestedContainer = try container.nestedUnkeyedContainer(forKey: .custom)
            let red = try nestedContainer.decode(Float.self)
            let green = try nestedContainer.decode(Float.self)
            let blue = try nestedContainer.decode(Float.self)
            let alpha = try nestedContainer.decode(Float.self)
            
            self = PHNThemeColor.custom(red: red, green: green, blue: blue, alpha: alpha)
        default:
            throw DecodingError.dataCorrupted(
                        DecodingError.Context(
                            codingPath: container.codingPath,
                            debugDescription: "Unabled to decode theme color."
                        )
                    )
        }
    }
    
    /*
     • If the case doesn't have any associated values, we will encode true as its value to keep the JSON structure consistent.
     • For cases with one associated value that itself conforms to Codable, we will encode this value using the current case as a key.
     • For cases with multiple associated values, we will encode the values inside a nestedUnkeyedContainer maintaining their order.
     */
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .blue:
            try container.encode(true, forKey: .blue)
        case .red:
            try container.encode(true, forKey: .red)
        case .black:
            try container.encode(true, forKey: .black)
        case .purple:
            try container.encode(true, forKey: .purple)
        case .orange:
            try container.encode(true, forKey: .orange)
        case .yellow:
            try container.encode(true, forKey: .yellow)
        case .green:
            try container.encode(true, forKey: .green)
        case .white:
            try container.encode(true, forKey: .white)
        case .custom(let red, let green, let blue, let alpha):
            // With multiple associated values, encode the values inside a nestedUnkeyedContainer, maintaining their order.
            var nestedContainer = container.nestedUnkeyedContainer(forKey: .custom)
            try nestedContainer.encode(red)
            try nestedContainer.encode(green)
            try nestedContainer.encode(blue)
            try nestedContainer.encode(alpha)
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
            color = UIColor(red: CGFloat(red),
                          green: CGFloat(green),
                           blue: CGFloat(blue),
                          alpha: CGFloat(alpha))
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
    func determineBrightness(red: Float, green: Float, blue: Float) -> ColorBrightness {
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
