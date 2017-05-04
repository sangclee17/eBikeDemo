//
//  PeripheralsTableViewController.swift
//  ebikeDemo
//
//  Created by Sangchul Lee on 2/26/17.
//  Copyright © 2017 sangclee. All rights reserved.
//
import UIKit

class PeripheralsTableViewController: UITableViewController {
    
    var visiblePeripherals = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        didUpdateBleState(notification: nil)
        //Setup table refresh
        self.refreshControl?.addTarget(self, action: #selector(onTableRefresh(sender:)), for: .valueChanged)
        
        //Setup table view
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension
        
        //Start Scanning
        BleManager.sharedInstance.startScan()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Subscribe to Ble Notifications
        NotificationCenter.default.addObserver(self, selector: #selector(didDiscoverPeripheral), name: NSNotification.Name(rawValue: BleManager.BleNotifications.DidDiscoverPeripheral.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willConnectToPeripheral), name: NSNotification.Name(rawValue: BleManager.BleNotifications.WillConnectToPeripheral.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didConnectToPeripheral), name: NSNotification.Name(rawValue: BleManager.BleNotifications.DidConnectToPeripheral.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateBleState), name: NSNotification.Name(rawValue: BleManager.BleNotifications.DidUpdateBleState.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didDisconnectFromPeripheral), name: NSNotification.Name(rawValue: BleManager.BleNotifications.DidDisconnectFromPeripheral.rawValue), object: nil)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: BleManager.BleNotifications.DidDiscoverPeripheral.rawValue), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: BleManager.BleNotifications.WillConnectToPeripheral.rawValue), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: BleManager.BleNotifications.DidDisconnectFromPeripheral.rawValue), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: BleManager.BleNotifications.DidConnectToPeripheral.rawValue), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: BleManager.BleNotifications.DidUpdateBleState.rawValue), object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func onTableRefresh(sender: AnyObject) {
        
        visiblePeripherals.removeAll()
        tableView.reloadData()
        BleManager.sharedInstance.refreshPeripherals()
        refreshControl?.endRefreshing()
    }
    
    func didDiscoverPeripheral(notification: Notification) {
        DispatchQueue.main.async { [unowned self] in
            guard let userInfo = notification.userInfo, let identifierString = userInfo["uuid"] as? String else {
                return
            }
            
            if (self.visiblePeripherals.contains(identifierString)) {
                return
            } else {
                self.visiblePeripherals.append(identifierString)
            }
            self.tableView.reloadData()
        }
    }
    
    func willConnectToPeripheral(notification: Notification) {
        
        DispatchQueue.main.async { [unowned self] in
            let alert = UIAlertController(title: "Notification", message: "Connecting...", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: {(_) -> Void in
                if let peripheral = BleManager.sharedInstance.blePeripheralConnected {
                    BleManager.sharedInstance.disconnect(blePeripheral: peripheral)
                }
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func didConnectToPeripheral(notification: Notification) {
        
        DispatchQueue.main.async { [unowned self] in
            // Dismiss current dialog
            if self.presentedViewController != nil {
                self.dismiss(animated: true, completion: { [unowned self](_) -> Void in
                    self.pushToNextView()
                })
            }
            else {
                self.pushToNextView()
            }
        }
    }
    
    func pushToNextView() {
        if BleManager.sharedInstance.blePeripheralConnected!.name == "Adafruit Bluefruit LE" {
            BleManager.sharedInstance.stopScan()
            let LocationViewController = self.storyboard?.instantiateViewController(withIdentifier: "LocationViewController") as! LocationViewController
            self.navigationController?.pushViewController(LocationViewController, animated: true)
        }
        else {
            BleManager.sharedInstance.stopScan()
            let ConnectedPeripheralViewController = self.storyboard?.instantiateViewController(withIdentifier: "ConnectedPeripheralViewController") as! ConnectedPeripheralViewController
            ConnectedPeripheralViewController.selectedPeripheral = BleManager.sharedInstance.blePeripheralConnected
            self.navigationController?.pushViewController(ConnectedPeripheralViewController, animated: true)
        }
    }
    
    func didDisconnectFromPeripheral(notification: Notification) {
        DispatchQueue.main.async { [unowned self] in
            guard let userInfo = notification.userInfo, let identifierString = userInfo["uuid"] as? String else {
                return
            }
            let bleManager = BleManager.sharedInstance
            let blePeripheralsFound = bleManager.blePeripheralsFound
            var peripheralName: String? = " "
            if let blePeripheralFound = blePeripheralsFound[identifierString] {
                peripheralName = blePeripheralFound.name ?? "a peripheral"
            }
            
            if let selectedIndexPath = self.tableView.indexPathForSelectedRow {
                self.tableView.deselectRow(at: selectedIndexPath, animated: true)
            }
            
            let alert = UIAlertController(title: "Notification", message: "disconnect from \(String(describing: peripheralName))", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            self.tableView.reloadData()
        }
    }
    
    func didUpdateBleState(notification: Notification?) {
            guard let state = BleManager.sharedInstance.centralManager?.state else {
                return
            }
            
            // Check if there is any error
            var errorMessage: String?
            switch state {
            case .unsupported:
                errorMessage = "This device doesn't support Bluetooth Low Energy"
            case .unauthorized:
                errorMessage = "This app is not authorized to use the Bluetooth Low Energy"
            case .poweredOff:
                errorMessage = "Bluetooth is currently powered off"
            default:
                errorMessage = nil
            }
            if let errorMessage = errorMessage {
                let alert = UIAlertController(title: "Notification", message: errorMessage, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let numOfTableItems = visiblePeripherals.count
        return numOfTableItems
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PeripheralCell", for: indexPath) as! PeripheralTableViewCell
        let bleManager = BleManager.sharedInstance
        let blePeripheralsFound = bleManager.blePeripherals()
        
        if let peripheralFound = blePeripheralsFound[visiblePeripherals[indexPath.row]] {
            if peripheralFound.connectable == "No" {
                cell.accessoryType = .none
            }
            cell.setupWithPeripheral(peripheral: peripheralFound)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let bleManager = BleManager.sharedInstance
        let blePeripheralsFound = bleManager.blePeripherals()
        let row = indexPath.row
        
        synchronize(lock: visiblePeripherals as AnyObject) { [weak weakSelf = self] in
            if let selectedPeripheral = blePeripheralsFound[(weakSelf?.visiblePeripherals[row])!] {
                if selectedPeripheral.connectable == "Yes" {
                    bleManager.blePeripheralConnected = selectedPeripheral
                    bleManager.connect(blePeripheral: bleManager.blePeripheralConnected!)
                }
            }
        }
        
    }
}
