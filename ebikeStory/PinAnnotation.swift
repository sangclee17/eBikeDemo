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
        Location(title: "checkPoint3", latitude : -37.802736, longitude : 144.965134),
        Location(title: "checkPoint4", latitude : -37.802583, longitude : 144.963648),
        Location(title: "checkPoint5", latitude : -37.804533, longitude : 144.963337),
        Location(title: "checkPoint6", latitude : -37.804999, longitude : 144.967618),
        Location(title: "checkPoint7", latitude : -37.802964, longitude : 144.96823),
        Location(title: "checkPoint8", latitude : -37.803087, longitude : 144.969517),
        Location(title: "checkPoint9", latitude : -37.801057, longitude : 144.969828),
        //Location(title: "checkPoint10",latitude : -37.801002, longitude: 144.969134),
    ]
    
}
