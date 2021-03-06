//
//  File.swift
//  ebikeStory
//
//  Created by Sangchul Lee on 3/1/17.
//  Copyright © 2017 sangclee. All rights reserved.
//

import Foundation
import CoreBluetooth


class UartManager: NSObject {
    
    enum UartNotifications : String {
        case DidSendData = "didSendData"
        case DidReceiveData = "didReceiveData"
        case DidBecomeReady = "didBecomeReady"
    }
    
    // Constants
    fileprivate static let UartServiceUUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
    fileprivate static let RxCharacteristicUUID = "6e400003-b5a3-f393-e0a9-e50e24dcca9e"
    fileprivate static let TxCharacteristicUUID = "6e400002-b5a3-f393-e0a9-e50e24dcca9e"
    fileprivate static let TxMaxCharacters = 20
    
    // Manager
    static let sharedInstance = UartManager()
    
    // Bluetooth Uart
    var uartService: CBService?
    fileprivate var rxCharacteristic: CBCharacteristic?
    fileprivate var txCharacteristic: CBCharacteristic?
    
    var blePeripheral: BlePeripheral? {
        didSet {
            if blePeripheral?.peripheral.identifier != oldValue?.peripheral.identifier {
                // Discover UART
                resetService()
                if let blePeripheral = blePeripheral {
                    blePeripheral.peripheral.delegate = self
                    print("Uart: discover services")
                    blePeripheral.peripheral.discoverServices([CBUUID(string: UartManager.UartServiceUUID)])
                }
            }
        }
    }
    
    override init() {
        super.init()
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(didDisconnectFromPeripheral(_:)), name: NSNotification.Name(rawValue:"didDisconnectFromPeripheral"), object: nil)
    }
    
    deinit {
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: NSNotification.Name(rawValue:"didDisconnectFromPeripheral"), object: nil)
    }
    
    func didDisconnectFromPeripheral(_ notification: Notification) {
        blePeripheral = nil
        //resetService()
    }
    
    fileprivate func resetService() {
        uartService = nil
        rxCharacteristic = nil
        txCharacteristic = nil
    }
    
    func sendData(value: [UInt8]) {
        if let txCharacteristic = txCharacteristic, let blePeripheral = blePeripheral {
            let data = NSData(bytes: value, length: value.count)
            blePeripheral.peripheral.writeValue(data as Data, for: txCharacteristic, type: CBCharacteristicWriteType.withResponse)
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: UartNotifications.DidSendData.rawValue), object: nil, userInfo: ["data": value])
    }
    
    func isReady() -> Bool {
        return txCharacteristic != nil && rxCharacteristic != nil // &&  rxCharacteristic!.isNotifying
    }
}

// MARK: - CBPeripheralDelegate
extension UartManager: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        //print("UartManager: resetService because didModifyServices")
        resetService()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard blePeripheral != nil else {
            return
        }
        if uartService == nil {
            //print("Uart: discover Characteristics")
            if let services = peripheral.services {
                var found = false
                var i = 0
                while (!found && i < services.count) {
                    let service = services[i]
                    if (service.uuid.uuidString .caseInsensitiveCompare(UartManager.UartServiceUUID) == .orderedSame) {
                        found = true
                        uartService = service
                        
                        peripheral.discoverCharacteristics([CBUUID(string: UartManager.RxCharacteristicUUID), CBUUID(string: UartManager.TxCharacteristicUUID)], for: service)
                    }
                    i += 1
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        guard blePeripheral != nil else {
            return
        }
        
        if let uartService = uartService {
            if rxCharacteristic == nil || txCharacteristic == nil {
                if let characteristics = uartService.characteristics {
                    
                    for characteristic in characteristics {
                        //Tx
                        if characteristic.uuid.uuidString .caseInsensitiveCompare(UartManager.TxCharacteristicUUID) == .orderedSame {
                            txCharacteristic = characteristic
                        }
                            //Rx
                        else if characteristic.uuid.uuidString .caseInsensitiveCompare(UartManager.RxCharacteristicUUID) == .orderedSame {
                            rxCharacteristic = characteristic
                        }
                    }
                }
            }
            
            // Check if characteristics are ready
            if (rxCharacteristic != nil && txCharacteristic != nil) {
                // Set rx enabled
                peripheral.setNotifyValue(true, for: rxCharacteristic!)
                
                // Send notification that uart is ready
                NotificationCenter.default.post(name: Notification.Name(rawValue: UartNotifications.DidBecomeReady.rawValue), object: nil, userInfo:nil)
                //print("UartManager discovered characteristics for service")
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard blePeripheral != nil else {
            return
        }
        
        if let error = error {
            print("didWriteValueForCharacteristic \(characteristic.uuid) error = \(error)")
        }else {
            print("didWriteValueForCharacteristic successfully")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        guard blePeripheral != nil else {
            return
        }
        
        if let error = error {
            print("didUpdateNotificationStateForcharacteristic \(characteristic.uuid) error = \(error)")
        }else {
            //print("didUpadateNotificationForcharacteristic successfully")
        }
    }
    
    //Reading
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        guard blePeripheral != nil else {
            return
        }
        
        if characteristic == rxCharacteristic && characteristic.service == uartService {
            
            if let rxData = characteristic.value {
                let numberOfBytes = rxData.count
                var rxByteArray = [UInt8](repeating: 0, count: numberOfBytes)
                (rxData as NSData).getBytes(&rxByteArray, length: numberOfBytes)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: UartNotifications.DidReceiveData.rawValue), object: nil, userInfo: ["data": rxData])
            }
        }
    }
}
