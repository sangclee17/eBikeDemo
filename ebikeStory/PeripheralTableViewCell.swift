//
//  PeripheralTableViewCell.swift
//  ebikeStory
//
//  Created by Sangchul Lee on 2/28/17.
//  Copyright © 2017 sangclee. All rights reserved.
//

import UIKit
import CoreBluetooth

class PeripheralTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var UUIDLabel: UILabel!
    @IBOutlet weak var RSSILabel: UILabel!
    @IBOutlet weak var connectableLabel: UILabel!
    
    func setupWithPeripheral(peripheral: BlePeripheral) {
        
        nameLabel.text = peripheral.name
        UUIDLabel.text = peripheral.UUID
        RSSILabel.text = "RSSI: \(peripheral.RSSI)"
        connectableLabel.text = "Connectable: \(peripheral.connectable)"
    }
}
