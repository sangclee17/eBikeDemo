//
//  BleManager.swift
//  ebikeStory
//
//  Created by Sangchul Lee on 3/3/17.
//  Copyright © 2017 sangclee. All rights reserved.
//

import Foundation
import CoreBluetooth

class BleManager : NSObject, CBCentralManagerDelegate {
    
    //notification
    enum BleNotifications : String {
        case DidUpdateBleState = "didUpdateBleState"
        case DidStartScanning = "didStartScanning"
        case DidStopScanning = "didStopScanning"
        case DidDiscoverPeripheral = "didDiscoverPeripheral"
        case DidUnDiscoverPeripheral = "didUnDiscoverPeripheral"
        case WillConnectToPeripheral = "willConnectToPeripheral"
        case DidConnectToPeripheral = "didConnectToPeripheral"
        case WillDisconnectFromPeripheral = "willDisconnectFromPeripheral"
        case DidDisconnectFromPeripheral = "didDisconnectFromPeripheral"
    }
    
    static let sharedInstance = BleManager()
    var centralManager : CBCentralManager?
    
    //Scanning
    var blePeripheralsFound = [String : BlePeripheral]()
    var blePeripheralConnected: BlePeripheral?
    var scanTimer: Timer?
    var connectionAttemptTimer: Timer?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }
    
    func restoreCentralManager() {
        centralManager?.delegate = self
    }
    
    func startScan() {
        guard let centralManager = centralManager, centralManager.state != .poweredOff && centralManager.state != .unauthorized && centralManager.state != .unsupported else {
            print("startScan failed because central manager is not ready")
            return
        }
        guard centralManager.state == .poweredOn else {
            return
        }
        
        centralManager.scanForPeripherals(withServices: nil, options: nil)
        scanTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(self.stopScan), userInfo: nil, repeats: false)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: BleNotifications.DidStartScanning.rawValue), object: nil)
    }

    
    func stopScan() {
        centralManager?.stopScan()
        scanTimer?.invalidate()
        NotificationCenter.default.post(name: NSNotification.Name(BleNotifications.DidStopScanning.rawValue), object: nil)
    }
    
    func refreshPeripherals() {
        stopScan()
        
        blePeripheralsFound.removeAll()
            if let connected = blePeripheralConnected {
                blePeripheralsFound[connected.peripheral.identifier.uuidString] = connected
            }
        
        startScan()
    }
    
    func connect(blePeripheral: BlePeripheral) {
        NotificationCenter.default.post(name: NSNotification.Name(BleNotifications.WillConnectToPeripheral.rawValue), object: nil)
        centralManager?.connect(blePeripheral.peripheral, options: nil)
    }
    
    func disconnect(blePeripheral: BlePeripheral) {
        print("disconnecting fro: \(blePeripheral.name)")
        centralManager?.cancelPeripheralConnection(blePeripheral.peripheral)
        NotificationCenter.default.post(name: NSNotification.Name(BleNotifications.WillDisconnectFromPeripheral.rawValue), object: nil)
    }
    
    func discover(blePeripheral: BlePeripheral, serviceUUIDs:[CBUUID]?) {
        print("discover services")
        blePeripheral.peripheral.discoverServices(serviceUUIDs)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("centralManagerDidUpdateState \(central.state.rawValue)")
        
        if (central.state == .poweredOn) {
            startScan()
        }
        else {
            if let blePeripheralConnected = blePeripheralConnected {
                disconnect(blePeripheral: blePeripheralConnected)
            }
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: BleNotifications.DidUpdateBleState.rawValue), object: nil)
    }
    
    func timeoutPeripheralConnectionAttempt() {
        print("Peripheral connection attempt timed out.")
        if let connectedPeripheral = blePeripheralConnected {
            disconnect(blePeripheral: connectedPeripheral)
        }
        connectionAttemptTimer?.invalidate()
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let identifierString = peripheral.identifier.uuidString
        print("didDiscoverPeripheral \(peripheral.name)")
        
        synchronize(lock: blePeripheralsFound as AnyObject) {
            if let existingPeripheral = self.blePeripheralsFound[identifierString] {
                // Existing peripheral. Update advertisement data because each time is discovered the advertisement data could miss some of the keys (sometimes a sevice is there, and other times has dissapeared)
                
                existingPeripheral.RSSI = RSSI.intValue
                for (key, value) in advertisementData {
                    existingPeripheral.advertisementData.updateValue(value as AnyObject, forKey: key)
                }
                self.blePeripheralsFound[identifierString] = existingPeripheral
                
            }
            else {      // New peripheral found
                let blePeripheral = BlePeripheral(peripheral: peripheral, advertisementData: advertisementData as [String : AnyObject], RSSI: RSSI.intValue)
                self.blePeripheralsFound[identifierString] = blePeripheral
            }
        }
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: BleNotifications.DidDiscoverPeripheral.rawValue), object:nil, userInfo: ["uuid" : identifierString])
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("didConnectPeripheral: \(peripheral.name != nil ? peripheral.name! : "")")
        
        let identifier = peripheral.identifier.uuidString
        blePeripheralConnected = blePeripheralsFound[identifier]
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: BleNotifications.DidConnectToPeripheral.rawValue), object: nil, userInfo: ["uuid" : identifier])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("didDisconnectPeripheral: \(peripheral.name != nil ? peripheral.name! : "")")
        
        peripheral.delegate = nil
        if peripheral.identifier == blePeripheralConnected?.peripheral.identifier {
            self.blePeripheralConnected = nil
        }
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: BleNotifications.DidDisconnectFromPeripheral.rawValue), object: nil,  userInfo: ["uuid" : peripheral.identifier.uuidString])
    }
    
    func blePeripherals() -> [String : BlePeripheral] {
        var result : [String : BlePeripheral]?
        result = self.blePeripheralsFound
        synchronize(lock: blePeripheralsFound as AnyObject) { [unowned self] in
            result = self.blePeripheralsFound
        }
        print(result!)
        return result!
    }
}
