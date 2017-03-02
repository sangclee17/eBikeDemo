//
//  mapViewController.swift
//  ebikeStory
//
//  Created by Sangchul Lee on 2/27/17.
//  Copyright © 2017 sangclee. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    private let locationManager = CLLocationManager()
    private var myCurrentLocation = CLLocationCoordinate2D()
    private var myDestination = MKMapItem()
    
    //redo this part!!
    @IBOutlet weak var mapVi: MKMapView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let destination = CLLocationCoordinate2D(latitude: -37.801112, longitude: 144.967132)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = destination
        annotation.title    = "My destination"
        
        let placeMark = MKPlacemark(coordinate: destination, addressDictionary: nil)
        myDestination = MKMapItem(placemark: placeMark)
        
        mapVi.addAnnotation(annotation)
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.first
        
        if let locationDetected = location {
            
            myCurrentLocation = locationDetected.coordinate
            let span = MKCoordinateSpanMake(0.03, 0.03)
            let myLocation = CLLocationCoordinate2DMake(locationDetected.coordinate.latitude, locationDetected.coordinate.longitude)
            let region: MKCoordinateRegion = MKCoordinateRegionMake(myLocation, span)
            self.mapVi.setRegion(region, animated: true)
            self.mapVi.showsUserLocation = true
        }
        locationManager.stopUpdatingLocation()
    }
    
    @IBAction func showDirection(_ sender: Any) {
        
        let directionRequest = MKDirectionsRequest()
        directionRequest.source = MKMapItem.forCurrentLocation()
        
        directionRequest.destination = myDestination
        directionRequest.requestsAlternateRoutes = false
        directionRequest.transportType = .automobile
        
        let directions = MKDirections(request: directionRequest)
        
        directions.calculate(completionHandler: {[weak weakSelf = self](response, error) in
            if error != nil {
                print("ERROR\(error)")
            } else {
                if let directionResponse = response {
                    weakSelf?.showRoute (response: directionResponse)
                }
            }
        })
    }
    
    func showRoute (response: MKDirectionsResponse) {
        
        let overlays = mapVi.overlays
        mapVi.removeOverlays(overlays)
        
        for route in response.routes as [MKRoute] {
            mapVi.add(route.polyline, level: .aboveRoads)
            
            for stepRoute in route.steps {
                print(stepRoute.instructions)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.blue
        renderer.alpha = 0.7
        renderer.lineWidth = 4.0
        
        return renderer
    }
    
}
