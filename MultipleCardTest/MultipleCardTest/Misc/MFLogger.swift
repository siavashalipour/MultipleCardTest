//
//  MFLogger.swift
//  MultipleCardTest
//
//  Created by Siavash on 22/5/18.
//  Copyright © 2018 Maxwellforest. All rights reserved.
//

import Foundation
import SwiftyBeaver

struct MFBLogger {
    
    static var shared: SwiftyBeaver.Type {
        let log = SwiftyBeaver.self
        // add log destinations. at least one is needed!
        let console = ConsoleDestination()  // log to Xcode Console
        let file = FileDestination()  // log to default swiftybeaver.log file
        
        // use custom format and set console output to short time, log level & message
        console.format = "$DHH:mm:ss$d $L $M"
        
        // add the destinations to SwiftyBeaver
        log.addDestination(console)
        log.addDestination(file)
        return log
    }
}
