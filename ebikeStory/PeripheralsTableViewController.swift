//
//  PeripheralsTableViewController.swift
//  ebikeDemo
//
//  Created by Sangchul Lee on 2/26/17.
//  Copyright © 2017 sangclee. All rights reserved.
//
import UIKit
import CoreBluetooth

struct Peripheral {
    var peripheral: CBPeripheral
    var name: String?
    var UUID: String
    var RSSI: String
    var connectable = "No"
    var uartData = UartData()
    
    init(peripheral: CBPeripheral, RSSI: String, advertisementDictionary: NSDictionary) {
        self.peripheral = peripheral
        name = peripheral.name ?? "No name."
        UUID = peripheral.identifier.uuidString
        self.RSSI = RSSI
        if let isConnectable = advertisementDictionary[CBAdvertisementDataIsConnectable] as? NSNumber {
            connectable = (isConnectable.boolValue) ? "Yes" : "No"
        }
    }
}

class PeripheralsTableViewController: UITableViewController, CBCentralManagerDelegate {
    
    var centralManager: CBCentralManager!
    var isBluetoothEnabled = false
    var visiblePeripheralUUIDs = NSMutableOrderedSet()
    var visiblePeripherals = [String: Peripheral]()
    var scanTimer: Timer?
    var connectionAttemptTimer: Timer?
    var connectedPeripheral: CBPeripheral?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 134
        tableView.rowHeight = UITableViewAutomaticDimension
        
        self.refreshControl?.addTarget(self, action: #selector(self.startScanning), for: .valueChanged)
    }
   
    override func viewDidAppear(_ animated: Bool) {
        if isBluetoothEnabled {
            if let peripheral = connectedPeripheral {
                centralManager.cancelPeripheralConnection(peripheral)
            }
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        var printString: String
        switch central.state {
        case .poweredOff:
            printString = "Bluetooth hardware powered off."
            isBluetoothEnabled = false
        case .poweredOn:
            printString = "Bluetooth hardware powered on."
            isBluetoothEnabled = true
            startScanning()
        case .resetting:
            printString = "Bluetooth hardware is resetting."
            isBluetoothEnabled = false
        case .unauthorized:
            printString = "Bluetooth hardware is unauthorized."
            isBluetoothEnabled = false
        case .unsupported:
            printString = "Bluetooth hardware is unsupported."
            isBluetoothEnabled = false
        case .unknown:
            printString = "Bluetooth hardware state is unknown."
            isBluetoothEnabled = false
        }
        print("State updated to: \(printString)")
    }
    
    func startScanning() {
        print("Started scanning")
        visiblePeripheralUUIDs.removeAllObjects()
        visiblePeripherals.removeAll(keepingCapacity: true)
        tableView.reloadData()
        centralManager.scanForPeripherals(withServices:nil, options: nil)
        scanTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(self.stopScanning), userInfo: nil, repeats: false)
    }
    
    func stopScanning() {
        print("Stopped scanning")
        print("Found\(visiblePeripherals.count) peripherals.")
        centralManager.stopScan()
        refreshControl?.endRefreshing()
        scanTimer?.invalidate()
    }
    
    func timeoutPeripheralConnectionAttempt() {
        print("Peripheral connection attempt timed out.")
        if let connectedPeripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(connectedPeripheral)
        }
        connectionAttemptTimer?.invalidate()
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Peripheral found with name: \(peripheral.name)\nUUID: \(peripheral.identifier.uuidString)\nRSSI: \(RSSI)\nAdvertisement Data: \(advertisementData)")
        visiblePeripheralUUIDs.add(peripheral.identifier.uuidString)
        visiblePeripherals[peripheral.identifier.uuidString] = Peripheral(peripheral: peripheral, RSSI: RSSI.stringValue, advertisementDictionary: advertisementData as NSDictionary)
        tableView.reloadData()
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Peripheral connected: \(peripheral.name ?? peripheral.identifier.uuidString)")
        connectionAttemptTimer?.invalidate()
        let ConnectedPeripheralViewController = storyboard?.instantiateViewController(withIdentifier: "ConnectedPeripheralViewController") as! ConnectedPeripheralViewController
        ConnectedPeripheralViewController.peripheral = peripheral
        navigationController?.pushViewController(ConnectedPeripheralViewController, animated: true)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if peripheral != connectedPeripheral {
            print("Disconnected peripheral was not the currently connected peripheral.")
        }
        else {
            connectedPeripheral = nil
        }
        if let error = error {
            print("Failed to disconnect from peripheral with error: \(error)")
        }
        else {
            print("Successfully disconnected from peripheral: \(peripheral.name ?? peripheral.identifier.uuidString)")
        }
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndexPath, animated: true)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect peripheral: \(peripheral.name ?? peripheral.identifier.uuidString)\nBecause of error: \(error)")
        connectedPeripheral = nil
        connectionAttemptTimer?.invalidate()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return visiblePeripherals.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PeripheralCell", for: indexPath) as! PeripheralTableViewCell
        if let visibleUUID = visiblePeripheralUUIDs[indexPath.row] as? String {
            if let visiblePeripheral = visiblePeripherals[visibleUUID] {
                if visiblePeripheral.connectable == "No" {
                    cell.accessoryType = .none
                }
                cell.setupWithPeripheral(peripheral: visiblePeripheral)
            }
        }
        return cell
    }
  
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let selectedUUID = visiblePeripheralUUIDs[indexPath.row] as? String {
            if let selectedPeripheral = visiblePeripherals[selectedUUID] {
                if selectedPeripheral.connectable == "Yes" {
                    connectedPeripheral = selectedPeripheral.peripheral
                    connectionAttemptTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.timeoutPeripheralConnectionAttempt), userInfo: nil, repeats: false)
                    centralManager.connect(connectedPeripheral!, options: nil)
                }
            }
        }
    }
    
}
