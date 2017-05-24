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
    @IBOutlet weak var baseTableView: UITableView!
    
    var selectedPeripheral: BlePeripheral!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        baseTableView.dataSource = self
        
        self.navigationItem.title = "Info"

    }
    
    override func viewDidAppear(_ animated: Bool) {
        //print("Peripheral: \(selectedPeripheral)")
        
        nameLabel.text = selectedPeripheral.name ?? "No Name"
        UUIDLabel.numberOfLines = 0;
        UUIDLabel.text = "UUID: \(selectedPeripheral.peripheral.identifier.uuidString)"
        RSSILabel.text = "RSSI: \(String(selectedPeripheral.RSSI))"
        
        selectedPeripheral.peripheral.delegate = self
        selectedPeripheral.peripheral.readRSSI()
        selectedPeripheral.peripheral.discoverServices(nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        DispatchQueue.main.async { [unowned self] in
            if let error = error {
                print(error)
            }
            else {
                self.baseTableView.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "List of BLE Services"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedPeripheral.peripheral.services?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let services = selectedPeripheral.peripheral.services else {
            return UITableViewCell()
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "serviceCell", for: indexPath)
        let service = services[indexPath.row]
        
        //print("Service UUID Desciption: \(service.uuid.description)")
        cell.textLabel?.text = service.uuid.description
        
        return cell
    }
 
}

