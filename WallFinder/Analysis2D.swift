//
//  Analysis2D.swift
//  PlaneFinder
//
//  Created by Rolf Lakaemper on 7/21/17.
//  Copyright © 2017 Rolf Lakaemper. All rights reserved.
//

import Foundation

class Analysis2D{
    
    /// Conversion: 2D [x,y,...] to 3D [x, levelY, z, ...], x=x, y=levelY, z=y
    /// - Parameter points: 2D [Double] [x,y,...]
    /// - Parameter levelY: the inserted y coordinate
    public static func to3Dxyz(points pts: [Double], levelY: Double = 0.0)->[Double]{
        var points = [Double]()
        points.reserveCapacity(pts.count * 3 / 2)
        for i in 0...pts.count/2-1{
            points.append(pts[i*2])
            points.append(levelY)
            points.append(pts[i*2+1])
        }
        return(points)
    }
    
    /// rotate: rotate 2D points (in situ)
    /// - Parameter points: the points (x,y,x,y,...)
    /// - Parameter angle: rotation angle in degrees
    static func rotateLocal( points pts: inout [Double], angle a: Double){
        let radAngle = a/180.0*Double.pi
        let c = cos(radAngle)
        let s = sin(radAngle)
        var count = 0
        while count < pts.count {
            let x = pts[count]*c - pts[count+1]*s
            let y = pts[count]*s + pts[count+1]*c
            pts[count] = x
            pts[count+1] = y
            count = count + 2
        }
        return
    }
    
    /// histogram1D: 2D -> 1D histogram-projection (accumulation) along x or y axis
    /// - Parameter points: the points (x,y,x,y,...)
    /// - Parameter dimension: target dimension, 0 = x, 1 = y (default: x)
    /// - Parameter resolution: histogram resolution (default 0.1)
    static func projectTo1D(points pts:[Double], direction startIndex: Int = 0, resolution: Double = 0.1)->[Double]{
        //
        // find min/max
        var minV = 1e20 as Double
        var maxV = -1e20 as Double
        var index = startIndex
        while index < pts.count {
            minV = Double.minimum(minV, pts[index])
            maxV = Double.maximum(maxV, pts[index])
            index = index + 2
        }
        //
        let nCells = Int((maxV-minV)/resolution) + 1
        var cells = [Double](repeating: 0, count: nCells)
        index = startIndex
        while index < pts.count {
            let cell = Int((pts[index] - minV)/resolution)
            cells[cell] = cells[cell] + 1
            index = index + 2
        }
        return(cells)
    }
    
    /// Bounding Box [minX, minY, maxX, maxY]
    /// - Parameter points: the points (x,y,x,y,...)
    /// - returns: Bounding Box as [sMin, yMin, xMax, yMax]
    public static func getBoundingBox(points pts: [Double])->[Double]{
        var minMax = [DBL_MAX, DBL_MAX, DBL_MIN, DBL_MIN]
        for i in 0...pts.count/2-1{
            if (pts[i*2] < minMax[0]){
                minMax[0] = pts[i*2]
            }
            if (pts[i*2] > minMax[2]){
                minMax[2] = pts[i*2]
            }
            if (pts[i*2+1] < minMax[1]){
                minMax[1] = pts[i*2+1]
            }
            if (pts[i*2+1] < minMax[3]){
                minMax[3] = pts[i*2+1]
            }
        }
        return(minMax)
    }
    
    /// findDominantDirection: returns angle to axis-align points
    /// Algorithm is based on entropy of projections in multiple
    /// directions. Assumes 90 degree layout of point set
    /// - Parameter points: the points (x,y,x,y,...)
    /// - Parameter angularStep: difference between checked angles. Default: 1.0
    /// - returns: angle in degrees
    static func findDominantDirection(points pts: [Double], from: Double = 0.0, to: Double = 90.0, angStep: Double = 1.0)->Double{
        var bestAngle = 0.0
        var bestEntropy = 1e20
        for angle in stride(from: from, to: to, by: angStep) {
            var rpts = pts
            Analysis2D.rotateLocal(points: &rpts, angle: Double(angle))
            let pZ = Analysis2D.projectTo1D(points:rpts, direction: 1)
            let pX = Analysis2D.projectTo1D(points:rpts, direction: 0)
            let e = Analysis1D.entropy(data:pZ)+Analysis1D.entropy(data:pX)
            if (e < bestEntropy){
                bestEntropy = e
                bestAngle = Double(angle)
            }
        }
        return(bestAngle)
    }
}
