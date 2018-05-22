//
//  CardFlows.swift
//  MultipleCardTest
//
//  Created by Siavash on 18/5/18.
//  Copyright © 2018 Maxwellforest. All rights reserved.
//

import Foundation

// MARK:- Card binding Flow
extension RxBluetoothKitService {
    func startCardBinding(for card: CardModel) {
        //        Read the FW battery
        //        Read the FW version
        //        Write the battery notifications ON
        //        Write the Connection parameters
        //        Write the FSM parameters
    }
    
    func reconnectOrTurnOnCard(_ card: CardModel) {
        //        Read the FW battery
        //        Read the FW version
        //        Write the battery notifications ON
        //        Diagnostic read of FSM parameters
        //        Write the Connection parameters
    }
    
    func doOTA(for card: CardModel) {
        //        App (Master) reads the FW battery
        //        App (Master) writes the Faster connection parameters as follows
        //        Min Interval = 16
        //        Max Interval = 32
        //        Slave Latency = 2
        //        Timeout = 1s
        //        App proceed the OTA (OTA packets exchange)
        //        App writes the slow parameters to the card
        //        App re-boots the card (Disconnection takes place)
        //        App re-connects with the card (Re-connection flow comes into action)
    }
    
    func unlink(_ card: CardModel) {
        //        App (Master) writes the FSM parameters (to make the card Un-commissioned)
        //        Card (Slave/FW) sends the response and App waits for the response
        //            Card sends the termination link to the App
        //        App sends the termination link to the Card
    }
    
    func trunOff(_ card: CardModel) {
        //        App (Master) writes the PM0 mode (flight mode) to the card
        //        Card (Slave/FW) sends the response and App waits for the response
        //        Card sends the termination link to the App
    }
}
