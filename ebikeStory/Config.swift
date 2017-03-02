//
//  Config.swift
//  ebikeStory
//
//  Created by Sangchul Lee on 3/3/17.
//  Copyright © 2017 sangclee. All rights reserved.
//

import Foundation

struct Config {
    
    #if DEBUG
    static let DEBUG = true
    #else
    static let DEBUG = false
    #endif
    
    // Peripheral list
    //    static let peripheralListShowOnlyWithUart = Config.DEBUG && false
    //    static let peripheralListSelectToConnect = Config.DEBUG && false
    
    // Uart
    static let uartShowAllUartCommunication = Config.DEBUG && true
    static let uartLogSend = Config.DEBUG && true
    static let uartLogReceive = Config.DEBUG && true
}
