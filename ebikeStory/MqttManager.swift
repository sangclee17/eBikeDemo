//
//  MqttManager.swift
//  ebikeStory
//
//  Created by Sangchul Lee on 5/4/17.
//  Copyright © 2017 sangclee. All rights reserved.
//

import Foundation
import CocoaMQTT

class MqttManager {
    
    static let sharedInstance = MqttManager()
    
    var mqtt: CocoaMQTT?
    
    func mqttSetting() {
        let clientID = "d:eh8yvz:EbikePhone:EbikeLocation"
        let serverHost = "eh8yvz.messaging.internetofthings.ibmcloud.com"
        mqtt = CocoaMQTT(clientID: clientID, host: serverHost, port: 1883)
        mqtt!.username = "use-token-auth"
        mqtt!.password = "Av?g4VdpA*rwgveEgQ"
        mqtt!.enableSSL = false;
        mqtt!.delegate = self
    }
    
    func connectToServer() {
        mqtt!.connect()
    }
    
    func publishMessage(timeStamp: Date, Latitude: Double, Longitude: Double, Speed: Double) {
        let message = "{\"d\": {\"TimeStamp\": \(timeStamp), \"Latitude\": \(Latitude), \"Longitude\": \(Longitude), \"Speed\": \(Speed)}}"
        mqtt!.publish("iot-2/evt/text/fmt/json", withString: message, qos: .qos1, retained: true, dup: true)
    }
}
extension MqttManager: CocoaMQTTDelegate {
    
    func mqtt(_ mqtt: CocoaMQTT, didConnect host: String, port: Int) {
        print("didConnect \(host):\(port)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        print("didConnectAck: \(ack)，rawValue: \(ack.rawValue)")
        if ack == .accept {
            print("didAccept")
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        print("didPublishMessage with message: \(String(describing: message.string))")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        print("didPublishAck with id: \(id)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16 ) {
        print("didReceivedMessage: \(String(describing: message.string)) with id \(id)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topic: String) {
        print("didSubscribeTopic to \(topic)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
        print("didUnsubscribeTopic to \(topic)")
    }
    
    func mqttDidPing(_ mqtt: CocoaMQTT) {
        print("didPing")
    }
    
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        print("didReceivePong")
    }
    
    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        print("mqttDidDisconnect \(err.debugDescription)")
    }
    
    func _console(_ info: String) {
        print("Delegate: \(info)")
    }
}
