//
//  ConnectedPeripheralViewController.swift
//  ebikeStory
//
//  Created by Sangchul Lee on 2/27/17.
//  Copyright © 2017 sangclee. All rights reserved.
//

import UIKit
import Foundation
import CoreBluetooth

class ConnectedPeripheralViewController: UIViewController, CBPeripheralDelegate, UITableViewDataSource {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var UUIDLabel: UILabel!
    @IBOutlet weak var RSSILabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    
    private let UartServiceUUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
    
    var peripheral: CBPeripheral!
    private var isUartPeripheral:Bool = false
    fileprivate var uartService: CBService?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("Peripheral: \(peripheral)")
        
        nameLabel.text = peripheral.name ?? "No Name"
        UUIDLabel.numberOfLines = 0;
        UUIDLabel.text = peripheral.identifier.uuidString
        
        peripheral.delegate = self
        peripheral.readRSSI()
        peripheral.discoverServices(nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("Did discover services.")
        if let error = error {
            print(error)
        }
        else {
            print("\(peripheral.services)")
            tableView.reloadData()
            checkingPeripheral()
        }
    }
    
    func checkingPeripheral() {
        if let services = peripheral.services {
            var found = false
            var i = 0
            while (!found && i < services.count) {
                let service = services[i]
                if (service.uuid.uuidString .caseInsensitiveCompare(UartServiceUUID) == .orderedSame) {
                    found = true
                    uartService = service
                    
                    /*peripheral.discoverCharacteristics([CBUUID(string: UartManager.RxCharacteristicUUID), CBUUID(string: UartManager.TxCharacteristicUUID)], for: service)*/
                }
                i += 1
            }
            if !found {
                if let navigationController = self.navigationController{
                        navigationController.popToRootViewController(animated:true)
                }
            }
        }
    
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        print("Did read RSSI.")
        if let error = error {
            print("Error getting RSSI: \(error)")
            RSSILabel.text = "Error getting RSSI."
        }
        else {
            RSSILabel.text = "\(RSSI.intValue)"
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripheral.services?.count ?? 0
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let services = peripheral.services else {
            return UITableViewCell()
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "serviceCell", for: indexPath)
        let service = services[indexPath.row]
        print("Service UUID Desciption: \(service.uuid.description)")
        cell.textLabel?.text = service.uuid.description
        
        return cell
    }
 
    
}
