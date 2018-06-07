//
//  Characteristic+Hashable.swift
//  MultipleCardTest
//
//  Created by Siavash on 14/5/18.
//  Copyright © 2018 Maxwellforest. All rights reserved.
//

import Foundation
import RxBluetoothKit

extension Characteristic: Hashable {
  
  // DJB Hashing
  public var hashValue: Int {
    let scalarArray: [UInt32] = []
    return scalarArray.reduce(5381) {
      ($0 << 5) &+ $0 &+ Int($1)
    }
  }
}
