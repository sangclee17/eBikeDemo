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

class LocationViewController: UIViewController {
    
    private let CLManager = CLLocationManager()
    private let directionRequest = MKDirectionsRequest()
    //private let locationManager = LocationManager()
    private var myLocations = [CLLocationCoordinate2D]()
    private var checkPoints = [Int]()
    private let timer = Timer()
    
    @IBOutlet weak var mapVi: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Setup CLManager
        CLManager.delegate = self
        if CLLocationManager.locationServicesEnabled() {
            CLManager.desiredAccuracy = kCLLocationAccuracyBest
            CLManager.distanceFilter = 10.0
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        CLManager.requestWhenInUseAuthorization()
        
        //Setup directionRequest
        directionRequest.source = MKMapItem.forCurrentLocation()
        directionRequest.destination = "   "
        directionRequest.requestsAlternateRoutes = false
        let directions = MKDirections(request: directionRequest)
        calculateDirection(directions: directions)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer.invalidate()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func degreesToRadians (value:Double) -> Double {
        return value * M_PI / 180.0
    }
    
    func radiansToDegrees (value:Double) -> Double {
        return value * 180.0 / M_PI
    }
    
    func bearingFromLocation(fromLocation: CLLocationCoordinate2D, toLocation: CLLocationCoordinate2D) -> CLLocationDirection {
        
        var bearing: CLLocationDirection
        
        let fromLat = degreesToRadians(value: fromLocation.latitude)
        let fromLon = degreesToRadians(value: fromLocation.longitude)
        let toLat = degreesToRadians(value: toLocation.latitude)
        let toLon = degreesToRadians(value: toLocation.longitude)
        
        let y = sin(toLon - fromLon) * cos(toLat)
        let x = cos(fromLat) * sin(toLat) - sin(fromLat) * cos(toLat) * cos(toLon - fromLon)
        bearing = radiansToDegrees( value: atan2(y, x) ) as CLLocationDirection
        
        bearing = (bearing + 360.0).truncatingRemainder(dividingBy: 360.0)
        return bearing
    }
    
    func calculateDirection(directions : MKDirections) {
        directions.calculate(completionHandler: {[weak weakself = self](response, error) in
            if error != nil {
                print("Error\(error)")
            } else {
                if let directionResponse = response {
                    weakself?.showRoute (response : directionResponse)
                }
            }
        })
    }
    
    func showRoute(response : MKDirectionsResponse) {
        let overlays = mapVi.overlays
        mapVi.removeOverlays(overlays)
        
        for route in response.routes as [MKRoute] {
            let pointCount = route.polyline.pointCount
            myLocations = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
            route.polyline.getCoordinates(&myLocations, range: NSRange(location: 0, length: pointCount))
            
            mapVi.add(route.polyline, level: .aboveRoads)
            
            for stepRoute in route.steps {
                let cloc = CLLocationCoordinate2DMake(stepRoute.polyline.coordinate.latitude, stepRoute.polyline.coordinate.longitude)
                if let index = myLocations.index(where: {$0.latitude == cloc.latitude && $0.longitude == cloc.longitude}) {
                    checkPoints.append(index)
                }
                print(stepRoute.instructions)
            }
        }
    }
}

extension LocationViewController : CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    }
}

extension LocationViewController : MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.blue
        renderer.alpha = 0.7
        renderer.lineWidth = 4.0
        
        return renderer
    }
}














