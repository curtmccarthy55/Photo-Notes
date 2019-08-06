//
//  PHNHudView.swift
//  Unroll2
//
//  Created by Curtis McCarthy on 7/24/19.
//  Copyright © 2019 Bluewraith. All rights reserved.
//

import UIKit

class PHNHudView: UIView {
    // Public properties
    var text: String?
    var type: String?
    
    class func hud(inView view: UIView, withType type: String?, animated: Bool) -> PHNHudView {
        let hudView = PHNHudView(frame: view.bounds)
        hudView.type = type
        hudView.isOpaque = false
        
        view.addSubview(hudView)
        view.isUserInteractionEnabled = false
        
        if hudView.type == "Success" {
            hudView.show(animated: animated)
        }
        
        return hudView
    }
    
    override func draw(_ rect: CGRect) {
        let boxWidth: CGFloat = 96
        let boxHeight: CGFloat = 96
        
        let boxRect = CGRect(x: round((bounds.size.width - boxWidth) / 2),
                             y: round((bounds.size.height - boxHeight) / 2),
                         width: boxWidth,
                        height: boxHeight)
        let roundedRect = UIBezierPath(roundedRect: boxRect, cornerRadius: 10)
        UIColor(white: 0.3, alpha: 0.8).setFill()
        roundedRect.fill()
        
        if type == "Success" {
            let image = UIImage(named: "Checkmark")!
            let imagePoint = CGPoint(x: center.x - round(image.size.width / 2.0),
                                     y: center.y - round(image.size.height / 2.0) - boxHeight / 8.0)
//            let imagePoint = CGPoint(x: center.x - CGFloat(roundf(Float(image.size.width / 2.0))), y: center.y - CGFloat(roundf(Float(image.size.height / 2.0))) - boxHeight / 8.0)
            image.draw(at: imagePoint)
        } else if type == "Pending" {
            let activityIndicator =  UIActivityIndicatorView()
            activityIndicator.frame = CGRect(x: bounds.origin.x,
                                             y: bounds.origin.y - (boxHeight / 8.0),
                                         width: bounds.size.width,
                                        height: bounds.size.height)
            activityIndicator.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            addSubview(activityIndicator)
            activityIndicator.startAnimating()
        }
        // Draw checkmark
        if let image = UIImage(named: "Checkmark") {
            let imagePoint = CGPoint(x: center.x - round(image.size.width / 2),
                                     y: center.y - round(image.size.height / 2) - boxHeight / 8)
            image.draw(at: imagePoint)
        }
        // Draw the text
        let attribs = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16), NSAttributedString.Key.foregroundColor: UIColor.white ]
        
        let textSize = text!.size(withAttributes: attribs)
        
        let textPoint = CGPoint(x: center.x - round(textSize.width / 2), y: center.y - round(textSize.height / 2) + boxHeight / 4)
        text!.draw(at: textPoint, withAttributes: attribs)
    }
    
    func show(animated: Bool) {
        if animated {
            alpha = 0
            transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [], animations: {
                self.alpha = 1
                self.transform = CGAffineTransform.identity
            }, completion: nil)
        }
        
        perform(#selector(removeHudView), with: self, afterDelay: 0.7)
    }
    
//    func hide() {
//        superview?.isUserInteractionEnabled = true
//        removeFromSuperview()
//    }
    
    @objc func removeHudView(_ hudView: PHNHudView) {
        UIView.animate(withDuration: 0.5) {
            hudView.alpha = 0
        }
    }
}
