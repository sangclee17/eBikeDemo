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
    
    fileprivate let CLManager = CLLocationManager()
    fileprivate let directionRequest = MKDirectionsRequest()
    fileprivate var pathToGo = [CLLocationCoordinate2D]()
    fileprivate var checkPoints = [Int]()
    fileprivate var locationUpdated = [CLLocation]()
    
    @IBOutlet weak var mapVi: MKMapView!
    
    @IBOutlet weak var locationLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Setup CLManager
        CLManager.delegate = self
        CLManager.desiredAccuracy = kCLLocationAccuracyBest
        CLManager.distanceFilter = 10.0
        
        //Setup directionRequest
        directionRequest.source = MKMapItem.forCurrentLocation()
        directionRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: -37.81425, longitude: 144.96395), addressDictionary: nil))
        directionRequest.requestsAlternateRoutes = false
        let directions = MKDirections(request: directionRequest)
        calculateDirection(directions: directions)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        CLManager.requestAlwaysAuthorization()
        CLManager.startUpdatingLocation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        locationUpdated.removeAll(keepingCapacity: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
            pathToGo = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
            route.polyline.getCoordinates(&pathToGo, range: NSRange(location: 0, length: pointCount))
            
            mapVi.add(route.polyline, level: .aboveRoads)
            
            for stepRoute in route.steps {
                let cloc = CLLocationCoordinate2DMake(stepRoute.polyline.coordinate.latitude, stepRoute.polyline.coordinate.longitude)
                if let index = pathToGo.index(where: {$0.latitude == cloc.latitude && $0.longitude == cloc.longitude}) {
                    checkPoints.append(index)
                }
                print(stepRoute.instructions)
            }
        }
    }
}

extension LocationViewController : CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //var distanceToCheckPoint : Double
        //var turnDirection : Double
        
        for location in locations {
            let howRecent = location.timestamp.timeIntervalSinceNow
            
            if abs(howRecent) < 10 && location.horizontalAccuracy < 20 {
                if locationUpdated.count > 0 {
                    if let checkPoint = checkPoints.first, checkPoints.first != checkPoints.last {
                        let distanceToCheckPoint = distance(from: location.coordinate, to: pathToGo[checkPoint])
                        if distanceToCheckPoint <= 100.0 && distanceToCheckPoint >= 90.0 {
                            let turnDirection = bearingFromLocation(fromLocation: location.coordinate, toLocation: pathToGo[checkPoint + 1])
                            if turnDirection > 0 && turnDirection <= 90 {
                                locationLabel.text = "ready right turn \(distanceToCheckPoint)"
                            }else if turnDirection >= 270 && turnDirection < 360 {
                                locationLabel.text = "ready left turn \(distanceToCheckPoint)"
                            }
                        }
                        else if distanceToCheckPoint <= 60.0 && distanceToCheckPoint >= 50.0 {
                            let turnDirection = bearingFromLocation(fromLocation: location.coordinate, toLocation: pathToGo[checkPoint + 1])
                            if turnDirection > 0 && turnDirection <= 90 {
                                locationLabel.text = "ready right turn \(distanceToCheckPoint)"
                            }else if turnDirection >= 270 && turnDirection < 360 {
                                locationLabel.text = "ready left turn \(distanceToCheckPoint)"
                            }
                        }
                        else if distanceToCheckPoint <= 20.0 && distanceToCheckPoint >= 10.0 {
                            let turnDirection = bearingFromLocation(fromLocation: location.coordinate, toLocation: pathToGo[checkPoint + 1])
                            if turnDirection > 0 && turnDirection <= 90 {
                                locationLabel.text = "ready right turn \(distanceToCheckPoint)"
                            }else if turnDirection >= 270 && turnDirection < 360 {
                                locationLabel.text = "ready left turn \(distanceToCheckPoint)"
                            }
                        }
                        else if distanceToCheckPoint <= 5.5 {
                            checkPoints.remove(at: 0)
                            if checkPoints.isEmpty {
                                CLManager.stopUpdatingLocation()
                            }
                        }
                    }
                    var coords = [CLLocationCoordinate2D]()
                    coords.append(locationUpdated.last!.coordinate)
                    coords.append(location.coordinate)
                    let span = MKCoordinateSpanMake(0.03, 0.03)
                    let currentLocation = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
                    let region: MKCoordinateRegion = MKCoordinateRegionMake(currentLocation, span)
                    self.mapVi.setRegion(region, animated: true)
                    
                    self.mapVi.remove(MKPolyline(coordinates: &coords, count: coords.count))
                    self.mapVi.showsUserLocation = true
                }
                locationUpdated.append(location)
            }
        }
    }
    
    func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let to = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return from.distance(from: to)
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
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("didFailWithError error = \(error)")
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














