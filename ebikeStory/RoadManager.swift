//
//  RoadManager.swift
//  ebikeStory
//
//  Created by Sangchul Lee on 3/24/17.
//  Copyright © 2017 sangclee. All rights reserved.
//

import Foundation
import CoreGraphics
import CoreLocation

class RoadManager: NSObject {
    
    final let MIN_SPEED = 2.0 // unit m/s
    final let MAX_DISTANCE_FROM_PATH = 200.0 // unit meter
    final let INITIAL_NOTIFICATION_RANGE = 40.0...60.0
    final let SECOND_NOTIFICATION_RANGE = 10.0...30.0
    
    var prevPoint : CLLocationCoordinate2D?
    var pointWithMinDistance : CLLocationCoordinate2D?
    var nextPoint : CLLocationCoordinate2D?


    var checkPoints = [CLLocationCoordinate2D]()

    override init() {
        super.init()
        //UartManager.sharedInstance.blePeripheral = BleManager.sharedInstance.blePeripheralConnected
    }
    
    func printPath() {
        for ad in checkPoints {
            print(ad.latitude)
        }
    }
    
    func traceUserLocation (location : CLLocation) {
        
        var MinDistanceFromPath = 5000.00 // unit meter
        let userCoordinate = location.coordinate
        
        for i in 0..<checkPoints.count {
            let newDistance = self.distance(from: userCoordinate, to: checkPoints[i])
            if newDistance < MinDistanceFromPath {
                MinDistanceFromPath = newDistance
                prevPoint = checkPoints[max(i-1,0)]
                pointWithMinDistance = checkPoints[i]
                nextPoint = checkPoints[min(i+1,checkPoints.count - 1)]
            }
        }
        
        let distanceToCheckPoint = distance(from: userCoordinate, to: pointWithMinDistance!)
        let turnDirection = bearingFromLocation(fromLocation: userCoordinate, toLocation: nextPoint!)
        let headingToCheckPoint = checkHeadingToCheckPoint(point: userCoordinate, toLineSegment: prevPoint!, and: pointWithMinDistance!)
        
        if INITIAL_NOTIFICATION_RANGE ~= distanceToCheckPoint && headingToCheckPoint && location.speed > MIN_SPEED {
            print(turnDirection)
        }
        else if SECOND_NOTIFICATION_RANGE ~= distanceToCheckPoint && headingToCheckPoint && location.speed > MIN_SPEED {
            print(turnDirection)
        }
        
        if MinDistanceFromPath > MAX_DISTANCE_FROM_PATH {
            let OnLineSegmentBetweenPrevPointAndPointWithMinDistance = lineSegmentDistanceFromAPoint(point: userCoordinate, toLineSegment: prevPoint!, and: pointWithMinDistance!)
            let OnLineSegmentBetweenPointWithMinDistanceAndNextPoint = lineSegmentDistanceFromAPoint(point: userCoordinate, toLineSegment: pointWithMinDistance!, and: nextPoint!)
            MinDistanceFromPath = Double(min(min(OnLineSegmentBetweenPrevPointAndPointWithMinDistance, OnLineSegmentBetweenPointWithMinDistanceAndNextPoint),CGFloat(MinDistanceFromPath)))
            if MinDistanceFromPath > MAX_DISTANCE_FROM_PATH {
                print("user's off the path. recalculating path....")
            }
        }
    }
    
    func lineSegmentDistanceFromAPoint (point P: CLLocationCoordinate2D,
                                        toLineSegment V: CLLocationCoordinate2D, and W: CLLocationCoordinate2D) -> CGFloat {
        let p = CGPoint(x: P.latitude, y: P.longitude)
        let v = CGPoint(x: V.latitude, y: V.longitude)
        let w = CGPoint(x: W.latitude, y: W.longitude)
        
        let pv_dx = p.x - v.x
        let pv_dy = p.y - v.y
        let wv_dx = w.x - v.x
        let wv_dy = w.y - v.y
        
        let dot = pv_dx * wv_dx + pv_dy * wv_dy
        let len_sq = wv_dx * wv_dx + wv_dy * wv_dy
        let param = dot / len_sq
        
        //intersection of normal to vw that goes through p
        var int_x, int_y: CGFloat
        
        if param < 0 || (v.x == w.x && v.y == w.y) {
            int_x = v.x
            int_y = v.y
        } else if param > 1 {
            int_x = w.x
            int_y = w.y
        } else {
            int_x = v.x + param * wv_dx
            int_y = v.y + param * wv_dy
        }
        
        // Components of normal
        let dx = p.x - int_x
        let dy = p.y - int_y
        
        return sqrt(dx * dx + dy * dy)
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
    
    func bearingFromLocation(fromLocation: CLLocationCoordinate2D, toLocation: CLLocationCoordinate2D) -> String {
        
        var bearing: CLLocationDirection
        
        let fromLat = degreesToRadians(value: fromLocation.latitude)
        let fromLon = degreesToRadians(value: fromLocation.longitude)
        let toLat = degreesToRadians(value: toLocation.latitude)
        let toLon = degreesToRadians(value: toLocation.longitude)
        
        let y = sin(toLon - fromLon) * cos(toLat)
        let x = cos(fromLat) * sin(toLat) - sin(fromLat) * cos(toLat) * cos(toLon - fromLon)
        bearing = radiansToDegrees( value: atan2(y, x) ) as CLLocationDirection
        
        bearing = (bearing + 360.0).truncatingRemainder(dividingBy: 360.0)
        
        if bearing > 20 && bearing <= 90 {
            return "RIGHT"
        }
        else if bearing >= 270 && bearing < 340 {
            return "LEFT"
        }
        else {
            return "STRAIGHT"
        }
    }
    
    func checkHeadingToCheckPoint(point P: CLLocationCoordinate2D,
                                  toLineSegment V: CLLocationCoordinate2D, and W: CLLocationCoordinate2D)-> Bool {
        let p = CGPoint(x: P.latitude, y: P.longitude)
        let v = CGPoint(x: V.latitude, y: V.longitude)
        let w = CGPoint(x: W.latitude, y: W.longitude)
        
        let pv_dx = p.x - v.x
        let pv_dy = p.y - v.y
        let wv_dx = w.x - v.x
        let wv_dy = w.y - v.y
        
        let dot = pv_dx * wv_dx + pv_dy * wv_dy
        let len_sq = wv_dx * wv_dx + wv_dy * wv_dy
        let param = dot / len_sq
        
        if param > 0 && param < 1{
            return true
        }
        return false
    }
}



