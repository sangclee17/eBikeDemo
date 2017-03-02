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
    fileprivate static let UartServiceUUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
    static let RxCharacteristicUUID = "6e400003-b5a3-f393-e0a9-e50e24dcca9e"
    fileprivate static let TxCharacteristicUUID = "6e400002-b5a3-f393-e0a9-e50e24dcca9e"
    fileprivate static let TxMaxCharacters = 20
    
    // Manager
    static let sharedInstance = UartManager()
    
    // Bluetooth Uart
    fileprivate var uartService: CBService?
    fileprivate var rxCharacteristic: CBCharacteristic?
    fileprivate var txCharacteristic: CBCharacteristic?
    fileprivate var txWriteType = CBCharacteristicWriteType.withResponse
    
    var blePeripheral: Peripheral? {
        didSet {
            if blePeripheral?.peripheral.identifier != oldValue?.peripheral.identifier {
                // Discover UART
                resetService()
                if let blePeripheral = blePeripheral {
                    print("Uart: discover services")
                    blePeripheral.peripheral.discoverServices([CBUUID(string: UartManager.UartServiceUUID)])
                }
            }
        }
    }
    
    // Data
    var dataBuffer = [UartDataChunk]()
    var dataBufferEnabled = Config.uartShowAllUartCommunication
    
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
        clearData()
        blePeripheral = nil
        resetService()
    }
    
    fileprivate func resetService() {
        uartService = nil
        rxCharacteristic = nil
        txCharacteristic = nil
    }
    
    /*
     // Send
     let data0 = 0xe0 + UInt8(pin.digitalPinId)
     let data1 = UInt8(value & 0x7f)         //only 7 bottom bits
     let data2 = UInt8(value >> 7)           //top bit in second byte
     
     let bytes:[UInt8] = [data0, data1, data2]
     let data = Data(bytes: UnsafePointer<UInt8>(bytes), count: bytes.count)
     UartManager.sharedInstance.sendData(data)
     */
    
    func sendData(_ data: Data) {
        let dataChunk = UartDataChunk(timestamp: CFAbsoluteTimeGetCurrent(), mode: .tx, data: data)
        sendChunk(dataChunk)
    }
    
    func sendChunk(_ dataChunk: UartDataChunk) {
        
        if let txCharacteristic = txCharacteristic, let blePeripheral = blePeripheral {
            let data = dataChunk.data
            
            if dataBufferEnabled {
                blePeripheral.uartData.sentBytes += data.count
                dataBuffer.append(dataChunk)
            }
            
            // Split data  in txmaxcharacters bytes packets
            var offset = 0
            repeat {
                let chunkSize = min(data.count-offset, UartManager.TxMaxCharacters)
                let chunk = Data(bytesNoCopy: UnsafeMutablePointer<UInt8>(UnsafeMutablePointer<UInt8>(mutating: (data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count))+offset), count: chunkSize, deallocator: .none)
                if Config.uartLogSend {
                    print("send: \(hexString(chunk))")
                }
                blePeripheral.peripheral.writeValue(chunk, for: txCharacteristic, type: txWriteType)
                offset+=chunkSize
            }while(offset<data.count)
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: UartNotifications.DidSendData.rawValue), object: nil, userInfo:["dataChunk" : dataChunk]);
        }
        else {
            print("Error: sendChunk with uart not ready")
        }
    }
    
    func hexString(_ data: Data) -> String {
        var bytes = [UInt8](repeating: 0, count: data.count)
        (data as NSData).getBytes(&bytes, length: data.count)
        
        let hexString = NSMutableString()
        for byte in bytes {
            hexString.appendFormat("%02X ", UInt(byte))
        }
        
        return NSString(string: hexString) as String
    }
    
    fileprivate func receivedData(_ data: Data) {
        
        let dataChunk = UartDataChunk(timestamp: CFAbsoluteTimeGetCurrent(), mode: .rx, data: data)
        receivedChunk(dataChunk)
    }
    
    fileprivate func receivedChunk(_ dataChunk: UartDataChunk) {
        if Config.uartLogReceive {
            print("received: \(hexString(dataChunk.data))")
        }
        
        if dataBufferEnabled {
            blePeripheral?.uartData.receivedBytes += dataChunk.data.count
            dataBuffer.append(dataChunk)
        }
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: UartNotifications.DidReceiveData.rawValue), object: nil, userInfo:["dataChunk" : dataChunk]);
    }
    
    func isReady() -> Bool {
        return txCharacteristic != nil && rxCharacteristic != nil// &&  rxCharacteristic!.isNotifying
    }
    
    func clearData() {
        dataBuffer.removeAll()
        blePeripheral?.uartData.receivedBytes = 0
        blePeripheral?.uartData.sentBytes = 0
    }
}

// MARK: - CBPeripheralDelegate
extension UartManager: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        print("UartManager: resetService because didModifyServices")
        resetService()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        guard blePeripheral != nil else {
            return
        }
        
        if uartService == nil {
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
        
        //DLog("uart didDiscoverCharacteristicsForService")
        if let uartService = uartService, rxCharacteristic == nil || txCharacteristic == nil {
            if rxCharacteristic == nil || txCharacteristic == nil {
                if let characteristics = uartService.characteristics {
                    var found = false
                    var i = 0
                    while !found && i < characteristics.count {
                        let characteristic = characteristics[i]
                        if characteristic.uuid.uuidString .caseInsensitiveCompare(UartManager.RxCharacteristicUUID) == .orderedSame {
                            rxCharacteristic = characteristic
                        }
                        else if characteristic.uuid.uuidString .caseInsensitiveCompare(UartManager.TxCharacteristicUUID) == .orderedSame {
                            txCharacteristic = characteristic
                            txWriteType = characteristic.properties.contains(.writeWithoutResponse) ? .withoutResponse:.withResponse
                            print("Uart: detected txWriteType: \(txWriteType.rawValue)")
                        }
                        found = rxCharacteristic != nil && txCharacteristic != nil
                        i += 1
                    }
                }
            }
            
            // Check if characteristics are ready
            if (rxCharacteristic != nil && txCharacteristic != nil) {
                // Set rx enabled
                peripheral.setNotifyValue(true, for: rxCharacteristic!)
                
                // Send notification that uart is ready
                NotificationCenter.default.post(name: Notification.Name(rawValue: UartNotifications.DidBecomeReady.rawValue), object: nil, userInfo:nil)
                
                print("Uart: did become ready")
                
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        
        guard blePeripheral != nil else {
            return
        }
        
        print("didUpdateNotificationStateForCharacteristic")
        /*
         if characteristic == rxCharacteristic {
         if error != nil {
         DLog("Uart RX isNotifying error: \(error)")
         }
         else {
         if characteristic.isNotifying {
         DLog("Uart RX isNotifying: true")
         
         // Send notification that uart is ready
         NSNotificationCenter.defaultCenter().postNotificationName(UartNotifications.DidBecomeReady.rawValue, object: nil, userInfo:nil)
         }
         else {
         DLog("Uart RX isNotifying: false")
         }
         }
         }
         */
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        guard blePeripheral != nil else {
            return
        }
        
        
        if characteristic == rxCharacteristic && characteristic.service == uartService {
            
            if let characteristicDataValue = characteristic.value {
                receivedData(characteristicDataValue)
            }
        }
    }
}
