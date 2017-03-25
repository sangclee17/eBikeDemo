//
//  LocationManager.swift
//  ebikeStory
//
//  Created by Sangchul Lee on 3/9/17.
//  Copyright © 2017 sangclee. All rights reserved.
//

import Foundation

class LocationManager: NSObject {

    func start() {
        
        print("location manager start")
        NotificationCenter.default.addObserver(self, selector: #selector(LocationManager.didSendData), name: NSNotification.Name(rawValue: UartManager.UartNotifications.DidSendData.rawValue), object: nil)
    }
    
    func stop() {
        print("location manager stop")
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: UartManager.UartNotifications.DidSendData.rawValue), object: nil)
    }
    
    func didSendData(notification: Notification) {
        
    }
    
}
