//
//  PeripheralTestViewController.swift
//  ebikeStory
//
//  Created by Sangchul Lee on 3/7/17.
//  Copyright © 2017 sangclee. All rights reserved.
//

import UIKit

class PeripheralTestViewController: UIViewController {
    
    private let locationManager = LocationManager()

    @IBOutlet weak var MessageSent: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        UartManager.sharedInstance.blePeripheral = BleManager.sharedInstance.blePeripheralConnected
        
        if(UartManager.sharedInstance.isReady()) {
            //testSendingData()
            
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(PeripheralTestViewController.uartIsReady), name: NSNotification.Name(rawValue: UartManager.UartNotifications.DidBecomeReady.rawValue), object: nil)
        }
    }
    
    func uartIsReady(notifiction: Notification) {
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: UartManager.UartNotifications.DidBecomeReady.rawValue), object: nil)
        
        testSendingData()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print("location Manager view willAppear")
        //locationManager.start()

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        print("location Manager view willDisappear")
        
        locationManager.stop()
    }
    
    func testSendingData() {
        //let bytes:[UInt8] = [72,101,108,108,111,33]
        let bytes:[UInt8] = [82,76]
        UartManager.sharedInstance.sendData(value: bytes)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
