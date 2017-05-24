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
import simd

class RoadManager {
    
    final let MIN_SPEED = 1.5 // unit m/s
    final let MAX_OFF_THE_PATH = 70.0 // unit meter
    final let INITIAL_DISTANCE_FROM_PATH = 300.0 // unit meter
    final let INITIAL_NOTIFICATION_RANGE = 50.0...70.0 // unit meter
    final let SECOND_NOTIFICATION_RANGE = 20.0...40.0 // unit meter
    final let MINIMUM_DEGREE_THRESHOLD = 20.0
    final let L = UInt8(76)
    final let R = UInt8(82)
    final let F = UInt8(70)
    final let O = UInt8(79)
    final let LED_OFF = UInt8(78)
    final let LED_ON = UInt8(89)
    final let INCOMING_TURN = UInt8(49)
    final let TURN_NOW = UInt8(51)
    final let REACH_DESTINATION = UInt8(52)
    final let OFF_TRACK = UInt8(53)
    
    
    
    var prevPoint : CLLocationCoordinate2D?
    var pointWithMinDistance : CLLocationCoordinate2D?
    var nextPoint : CLLocationCoordinate2D?


    var checkPoints = [CLLocationCoordinate2D]()
    
    var directionLabel : String = ""
    
    func printPath() {
        for ad in checkPoints {
            print(ad.latitude, ad.longitude)
        }
    }
    
    func traceUserLocation (location : CLLocation) {
        var MinDistanceFromPath = INITIAL_DISTANCE_FROM_PATH // unit meter
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
        if let pointWithMinDistance = pointWithMinDistance, let prevPoint = prevPoint, let nextPoint = nextPoint {
            let distanceToCheckPoint = distance(from: userCoordinate, to: pointWithMinDistance)
            let turnDirection = getTurnDirection(prev: prevPoint, current: pointWithMinDistance, next: nextPoint)
            let headingToCheckPoint = checkHeadingToCheckPoint(point: userCoordinate, toLineSegment: prevPoint, and: pointWithMinDistance)
            
            if INITIAL_NOTIFICATION_RANGE ~= distanceToCheckPoint && headingToCheckPoint && location.speed > MIN_SPEED {
                self.directionLabel = (turnDirection.appending("\(distanceToCheckPoint)"))
                
                if turnDirection == "RIGHT" {
                    let bytes:[UInt8] = [R,INCOMING_TURN,LED_OFF]
                    UartManager.sharedInstance.sendData(value: bytes)
                }
                else if turnDirection == "LEFT" {
                    let bytes:[UInt8] = [L,INCOMING_TURN,LED_OFF]
                    UartManager.sharedInstance.sendData(value: bytes)
                }
            }
            else if SECOND_NOTIFICATION_RANGE ~= distanceToCheckPoint && headingToCheckPoint && location.speed > MIN_SPEED {
                if isEqualCoordinates(coordinate1: pointWithMinDistance, coordinate2: self.checkPoints.last!) {
                    self.directionLabel = "FINISH!!!"
                    let bytes:[UInt8] = [F,REACH_DESTINATION,LED_OFF]
                    UartManager.sharedInstance.sendData(value: bytes)
                    return
                }
                self.directionLabel = (turnDirection.appending("\(distanceToCheckPoint)"))
                
                if turnDirection == "RIGHT" {
                    let bytes:[UInt8] = [R,TURN_NOW,LED_OFF]
                    UartManager.sharedInstance.sendData(value: bytes)
                }
                else if turnDirection == "LEFT" {
                    let bytes:[UInt8] = [L,TURN_NOW,LED_OFF]
                    UartManager.sharedInstance.sendData(value: bytes)
                }
            }
            else if MinDistanceFromPath > MAX_OFF_THE_PATH && location.speed > MIN_SPEED {
                let OnLineSegmentBetweenPrevPointAndPointWithMinDistance = lineSegmentDistanceFromAPoint(point: userCoordinate, toLineSegment: prevPoint, and: pointWithMinDistance)
                let OnLineSegmentBetweenPointWithMinDistanceAndNextPoint = lineSegmentDistanceFromAPoint(point: userCoordinate, toLineSegment: pointWithMinDistance, and: nextPoint)
                MinDistanceFromPath = Double(min(min(OnLineSegmentBetweenPrevPointAndPointWithMinDistance, OnLineSegmentBetweenPointWithMinDistanceAndNextPoint),CGFloat(MinDistanceFromPath)))
                
                if MinDistanceFromPath > MAX_OFF_THE_PATH {
                    self.directionLabel = "user's off the path. recalculating path...."
                    let bytes:[UInt8] = [O,OFF_TRACK,LED_OFF]
                    UartManager.sharedInstance.sendData(value: bytes)
                }
            }
            else {
                self.directionLabel = "ready"
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
        
        return sqrt(dx * dx + dy * dy) * 100000   //unit to meter
    }
    
    func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let to = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return from.distance(from: to)
    }
    
    func degreesToRadians (value:Double) -> Double {
        return value * Double.pi / 180.0
    }
    
    func radiansToDegrees (value:Double) -> Double {
        return value * 180.0 / Double.pi
    }
    
    func getTurnDirection (prev: CLLocationCoordinate2D, current: CLLocationCoordinate2D, next: CLLocationCoordinate2D) -> String {
        let prevToCurrent = vector2(current.longitude - prev.longitude, current.latitude - prev.latitude)
        let currentToNext = vector2(next.longitude - current.longitude, next.latitude - current.latitude)
        let lenCurrentToPrev = length(prevToCurrent)
        let lenCurrentToNext = length(currentToNext)
        let dotProduct = dot(prevToCurrent, currentToNext)
        let theta = acos(dotProduct/lenCurrentToPrev/lenCurrentToNext)
        let theta_Degree = radiansToDegrees(value: theta)
        let crossProduct = cross(prevToCurrent, currentToNext).z
        
        if theta_Degree > MINIMUM_DEGREE_THRESHOLD && crossProduct < 0 {
            return "RIGHT"
        }
        else if theta_Degree > MINIMUM_DEGREE_THRESHOLD && crossProduct > 0 {
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
    
    func isEqualCoordinates(coordinate1 : CLLocationCoordinate2D, coordinate2 : CLLocationCoordinate2D) -> Bool {
        return (coordinate1.latitude == coordinate2.latitude) && (coordinate1.longitude == coordinate2.longitude)
    }
}



