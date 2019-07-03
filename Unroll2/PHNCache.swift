//
//  PHNCache.swift
//  Unroll2
//
//  Created by Curtis McCarthy on 7/3/19.
//  Copyright © 2019 Bluewraith. All rights reserved.
//

import UIKit

class PHNCache: NSCache<NSString, UIImage> {

    override init() {
        super.init()
        
        NotificationCenter.default.addObserver( self,
                                      selector: #selector(removeAllObjects),
                                          name: UIApplication.didReceiveMemoryWarningNotification,
                                        object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver( self,
                                             name: UIApplication.didReceiveMemoryWarningNotification,
                                           object: nil)
    }
}
