//
//  CardModel.swift
//  MultipleCardTest
//
//  Created by Siavash on 14/5/18.
//  Copyright © 2018 Maxwellforest. All rights reserved.
//

import Foundation
import RealmSwift
import RxBluetoothKit

struct CardModel {    
    var cardName: String
    var uuid: String
    var isConnected: Bool
    var peripheral: Peripheral?
}
