//
//  DataManager.swift
//  ebikeStory
//
//  Created by Sangchul Lee on 3/29/17.
//  Copyright © 2017 sangclee. All rights reserved.
//

import Foundation
import CoreLocation

class DataManager {
    
    var userLocation = [CLLocation]()
    
    var fileManager = FileManager.default
    let tmpDir = NSTemporaryDirectory()
    let fileName = "ebikeData.csv"
    
    func enumerateDirectory() -> String? {
        do {
            let files = try fileManager.contentsOfDirectory(atPath: tmpDir)
            if files.count > 0 {
                if files[0] == fileName {
                    print("eBikeData.csv found")
                    return files[0]
                } else {
                    print("files not found")
                    return nil
                }
            }
        }catch {
            print("\(error)")
        }
        return nil
    }
    
    func createCSV() {
        let filePath = URL(fileURLWithPath: tmpDir).appendingPathComponent(fileName)
        var csvText = "Time, Speed, Latitude, Longitude \n"
        
        for loc in userLocation {
            let newLine = "\(loc.timestamp), \(loc.speed), \(loc.coordinate.latitude), \(loc.coordinate.longitude) \n"
            csvText.append(newLine)
        }
        do {
            try csvText.write(to: filePath, atomically: true, encoding: String.Encoding.utf8)
            print("successfully created csv file")
        } catch {
            print("Fail to create file")
            print("\(error)")
        }
    }
    
    func deleteFile() {
        if let isFileInDir = self.enumerateDirectory() {
            let filePath = URL(fileURLWithPath: tmpDir).appendingPathComponent(isFileInDir)
            do {
                try fileManager.removeItem(at: filePath)
                print("Successfully removed file in temporay Directory")
            }catch {
                print("fail to remove tempDir/file")
                print("\(error)")
            }
        }
    }
}
