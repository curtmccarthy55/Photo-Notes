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

