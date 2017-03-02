//
//  UartDataChunk.swift
//  ebikeStory
//
//  Created by Sangchul Lee on 3/1/17.
//  Copyright © 2017 sangclee. All rights reserved.
//

import Foundation

class UartDataChunk {      // A chunk of data received or sent
    var timestamp : CFAbsoluteTime
    enum TransferMode {
        case tx
        case rx
    }
    var mode : TransferMode
    var data : Data
    init(timestamp: CFAbsoluteTime, mode: TransferMode, data: Data) {
        self.timestamp = timestamp
        self.mode = mode
        self.data = data
    }

}
