//
//  PinAnnotation.swift
//  ebikeStory
//
//  Created by Sangchul Lee on 3/23/17.
//  Copyright © 2017 sangclee. All rights reserved.
//

import Foundation

class PinAnnotation: NSObject {
    /*
    var title : String?
    var coordinate: CLLocationCoordinate2D

    init(title : String, coordinate : CLLocationCoordinate2D) {
        self.title = title
        self.coordinate = coordinate
    }
 */
    struct Location {
        let title: String
        let latitude: Double
        let longitude: Double
    }
    
    let locations = [
        //Location(title: "checkPoint1", latitude : -37.800815, longitude : 144.967589),
        Location(title: "checkPoint2", latitude : -37.800604, longitude : 144.965515),
        Location(title: "checkPoint2.5", latitude : -37.801595, longitude : 144.965351),
        Location(title: "checkPoint3", latitude : -37.802647, longitude : 144.965032),
        Location(title: "checkPoint4", latitude : -37.802574, longitude : 144.963756),
        Location(title: "checkPoint4.5", latitude : -37.803435, longitude : 144.963527),
        Location(title: "checkPoint5", latitude : -37.804465, longitude : 144.963348),
        Location(title: "checkPoint5.5", latitude : -37.804834, longitude : 144.965651),
        Location(title: "checkPoint6", latitude : -37.804986, longitude : 144.967527),
        Location(title: "checkPoint6.5", latitude : -37.80396, longitude : 144.967791),
        Location(title: "checkPoint7", latitude : -37.802969, longitude : 144.967911),
        Location(title: "checkPoint8", latitude : -37.803083, longitude : 144.969399),
        Location(title: "checkPoint9", latitude : -37.801133, longitude : 144.969812),
        Location(title: "checkPoint10",latitude : -37.80079, longitude: 144.967453),
    ]
    
}
