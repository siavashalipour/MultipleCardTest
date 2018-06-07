//
//  Result.swift
//  MultipleCardTest
//
//  Created by Siavash on 14/5/18.
//  Copyright © 2018 Maxwellforest. All rights reserved.
//

import Foundation

enum Result<T, E> {
  case success(T)
  case error(E)
}

enum BluetoothServicesError: Error {
  case peripheralNil
  case commissioningError
}
