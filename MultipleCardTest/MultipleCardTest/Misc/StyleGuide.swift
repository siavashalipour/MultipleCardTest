//
//  Styleguide.swift
//  MultipleCardTest
//
//  Created by Siavash on 14/5/18.
//  Copyright © 2018 Maxwellforest. All rights reserved.
//

import Foundation
import UIKit
// Color palette

extension UIColor {
  
  class var primary: UIColor {
    return UIColor(red: 45.0 / 255.0, green: 192.0 / 255.0, blue: 200.0 / 255.0, alpha: 1.0)
  }
  
  class var secondary: UIColor {
    return UIColor(red: 0.0, green: 120.0 / 255.0, blue: 1.0, alpha: 1.0)
  }
  
  class var red: UIColor {
    return UIColor(red: 1.0, green: 45.0 / 255.0, blue: 85.0 / 255.0, alpha: 1.0)
  }
  
  class var dark: UIColor {
    return UIColor(red: 0.0, green: 24.0 / 255.0, blue: 51.0 / 255.0, alpha: 1.0)
  }
  
  class var light: UIColor {
    return UIColor(white: 249.0 / 255.0, alpha: 1.0)
  }
  
}
// Text styles

extension UIFont {
  
  class var detailMonitorTitle: UIFont {
    return UIFont.systemFont(ofSize: 26.0, weight: .bold)
  }
  
  class var cellHeading: UIFont {
    return UIFont.systemFont(ofSize: 15.0, weight: .semibold)
  }
  
  class var cellTitle: UIFont {
    return UIFont.systemFont(ofSize: 16.0, weight: .bold)
  }
  
  class var addressStyle: UIFont {
    return UIFont.systemFont(ofSize: 18.0, weight: .medium)
  }
  
  class var detailTitle: UIFont {
    return UIFont.systemFont(ofSize: 24.0, weight: .bold)
  }
  
  class var statusConnected: UIFont {
    return UIFont.systemFont(ofSize: 18.0, weight: .semibold)
  }
  
  class var statusOff: UIFont {
    return UIFont.systemFont(ofSize: 18.0, weight: .semibold)
  }
  
  class var statusDetecting: UIFont {
    return UIFont.systemFont(ofSize: 19.0, weight: .semibold)
  }
  
  class var statusZone: UIFont {
    return UIFont.systemFont(ofSize: 18.0, weight: .semibold)
  }
  
}
