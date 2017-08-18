//
//  FeaturePoint.swift
//  LiveWallFinder
//
//  Created by Rolf Lakaemper on 7/27/17.
//  Copyright © 2017 Rolf Lakaemper. All rights reserved.
//

import Foundation
struct FeaturePoint: Hashable{
    //
    // fields
    var x: Float = 0
    var y: Float = 0
    var z: Float = 0
    
    //
    // Hashvalue
    var hashValue: Int {
        var hashValue = (Int(y) << 12) * 11 + (Int(x) << 6) * 13
        hashValue = hashValue + Int(z) * 51
        return hashValue
    }
    
    //
    // == operator
    static func ==(lhs: FeaturePoint, rhs: FeaturePoint) -> Bool {
        return (lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z)
    }
    
    //
    // initializer
    init(x: Float, y: Float, z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    //
    // convert to resolution units
    mutating func convertToResolutionUnits(resolution: Float){
        x = floor(x/resolution)
        y = floor(y/resolution)
        z = floor(z/resolution)
    }
    
    //
    // convert from resolution units to meters
    mutating func convertFromResolutionUnits(resolution: Float){
        x = x*resolution
        y = y*resolution
        z = z*resolution
    }
    
}
