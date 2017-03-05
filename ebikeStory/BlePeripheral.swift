//
//  BlePeripheral.swift
//  ebikeStory
//
//  Created by Sangchul Lee on 3/3/17.
//  Copyright © 2017 sangclee. All rights reserved.
//

import Foundation
import CoreBluetooth

class BlePeripheral {
    
    var peripheral : CBPeripheral!
    var advertisementData: [String: AnyObject]
    var RSSI: Int
    var UUID: String
    var connectable: String?
    var name: String? {
        get {
            return peripheral.name
        }
    }
    
    init(peripheral: CBPeripheral, advertisementData: [String: AnyObject], RSSI: Int) {
        self.peripheral = peripheral
        self.advertisementData = advertisementData
        self.RSSI = RSSI
        self.UUID = peripheral.identifier.uuidString
        if let isConnectable = advertisementData[CBAdvertisementDataIsConnectable] as? NSNumber {
            connectable = (isConnectable.boolValue) ? "Yes" : "No"
        }
    }
    
    fileprivate static let kUartServiceUUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e"    // UART service UUID
    
    func isUartAdvertised() -> Bool {
        
        var isUartAdvertised = false

        if let serviceUUIds = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
            isUartAdvertised = serviceUUIds.contains(CBUUID(string: BlePeripheral.kUartServiceUUID))
        }
        return isUartAdvertised
    }
    
    func hasUart() -> Bool {
        var hasUart = false
        if let services = peripheral.services {
            hasUart = services.contains(where: { (service : CBService) -> Bool in
                service.uuid.isEqual(CBUUID(string: BlePeripheral.kUartServiceUUID))
            })
        }
        return hasUart
    }
}
