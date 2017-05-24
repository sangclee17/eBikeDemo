//
//  LocationViewController.swift
//  ebikeStory
//
//  Created by Sangchul Lee on 3/11/17.
//  Copyright © 2017 sangclee. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import MessageUI

class LocationViewController: UIViewController {
    
    var pathToGo = [CLLocationCoordinate2D]()
    let pins = PinAnnotation()
    fileprivate let dataManager = DataManager()
    fileprivate let roadManager = RoadManager()
    fileprivate let mqttManager = MqttManager()
    
    lazy var locationManager: CLLocationManager = {
        [unowned self] in
        var location_manager = CLLocationManager()
        location_manager.delegate = self
        location_manager.desiredAccuracy = kCLLocationAccuracyBest
        location_manager.requestAlwaysAuthorization()
        location_manager.allowsBackgroundLocationUpdates = true
        //location_manager.pausesLocationUpdatesAutomatically = true
        // Movement threshold for new events
        location_manager.distanceFilter = 10
        return location_manager
    }()
    
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var label: UILabel!
    
    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            mapView.delegate = self
            mapView.showsUserLocation = true
        }
    }
    
    @IBAction func startPressed(_ sender: Any) {
        dataManager.userLocation.removeAll(keepingCapacity: false)
        pathToGo.removeAll(keepingCapacity: false)
        
        showRoute()
        startButton.isHidden = true
        mapView.isHidden = false
        stopButton.isHidden = false
        label.isHidden = false
        mqttManager.connectToServer()
        startLocationUpdates()
    }
    
    @IBAction func stopPressed(_ sender: Any) {
        locationManager.stopUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = false
        
        let sendMailAlert = UIAlertController(title: "Email Testing Data Notification", message: "Would you like to receive an email about the location history details of this participant?", preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: {(action) -> Void  in
            print("pressed the cancel button")
        })
        let ok =  UIAlertAction(title: "OK", style: .default, handler: {[unowned self] (action) -> Void in
            //send email and then clean up
            self.sendFileToMail()
        })
        sendMailAlert.addAction((ok))
        sendMailAlert.addAction((cancel))
        self.present(sendMailAlert, animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Start Uart Manager
        UartManager.sharedInstance.blePeripheral = BleManager.sharedInstance.blePeripheralConnected
        
        //configure buttons & label
        startButton.isHidden = false
        stopButton.isHidden = true
        label.isHidden = true
        mapView.isHidden = true
        
        //configure mqtt
        mqttManager.mqttSetting()
    }
    
    func sendFileToMail() {
        dataManager.createCSV()
        
        //send email
        let mailComposeViewController = configuredMailComposeViewController()
        if MFMailComposeViewController.canSendMail() {
            self.present(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    func configuredMailComposeViewController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        
        mailComposerVC.setToRecipients(["ibm.ebikeproject@gmail.com"]) // password: ebikeawesome
        mailComposerVC.setSubject("Ebike_Participant_Data")
        mailComposerVC.setMessageBody("Hi, \n\nThe .csv data export is attached\n\n\nSent from ebike app", isHTML: false)
        
        let fileURL = URL(fileURLWithPath: dataManager.tmpDir).appendingPathComponent(dataManager.fileName)
        do {
            try mailComposerVC.addAttachmentData(NSData(contentsOf: fileURL) as Data, mimeType: "text/csv", fileName: dataManager.fileName)
            print("File Data Loaded")
        } catch {
            print("fail to attach file")
            print("\(error)")
        }
        return mailComposerVC
    }
    
    func showSendMailErrorAlert() {
        DispatchQueue.main.async { [unowned self] in
            let sendMailErrorAlert = UIAlertController(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.", preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            sendMailErrorAlert.addAction(OKAction)
            self.present(sendMailErrorAlert, animated: true, completion: nil)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func startLocationUpdates() {
        //initiate locationManager
        locationManager.startUpdatingLocation()
    }
    
    func showRoute() {
        let locations = pins.locations
        for location in locations {
            let annotation = MKPointAnnotation()
            annotation.title = location.title
            annotation.coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            roadManager.checkPoints.append(annotation.coordinate)
            mapView.addAnnotation(annotation)
        }
        //draw polyLine between annotations
        let polyLine = MKPolyline (coordinates: &roadManager.checkPoints, count: roadManager.checkPoints.count)
        polyLine.title = "pathToFollow"
        mapView.add(polyLine)
    }
    
    func mapRegion() -> MKCoordinateRegion {
        if let currentLocation = dataManager.userLocation.last {
            return MKCoordinateRegion (
                center: currentLocation.coordinate,
                span: MKCoordinateSpanMake(0.01, 0.01))
        }
        else {
            return MKCoordinateRegion (
                center: CLLocationCoordinate2D(latitude: -25.274398, longitude: 133.77513599999997),
                span: MKCoordinateSpanMake(38, 38))
        }
    }
    
    func drawUserPolyLine(userLocation: CLLocation) {
        var coords = [CLLocationCoordinate2D]()
        coords.append(userLocation.coordinate)
        if let locationUpdated = dataManager.userLocation.last {
            coords.append(locationUpdated.coordinate)
            let polyLine = MKPolyline(coordinates: &coords, count: coords.count)
            polyLine.title = "userPath"
            self.mapView.add(polyLine)
        }
    }
}

extension LocationViewController : CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            let howRecent = location.timestamp.timeIntervalSinceNow
            if abs(howRecent)<10 && location.horizontalAccuracy<20 {
                
                dataManager.userLocation.append(location)
                
                mqttManager.publishMessage(timeStamp: location.timestamp, Latitude: location.coordinate.latitude, Longitude: location.coordinate.longitude, Speed: location.speed)
                
                roadManager.traceUserLocation(location: location)
                drawUserPolyLine(userLocation: location)
                self.label.text = roadManager.directionLabel
                self.mapView.region = mapRegion()
            }
        }
    }
}

extension LocationViewController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.alpha = 0.7
        renderer.lineWidth = 4.0
        
        if overlay.title!! == "pathToFollow" {
            renderer.strokeColor = UIColor.blue
        }
        else if overlay.title!! == "userPath" {
            renderer.strokeColor = UIColor.green
        }
        return renderer
    }
}

extension LocationViewController : MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dataManager.deleteFile()
        controller.dismiss(animated: true, completion: nil)
    }
}

