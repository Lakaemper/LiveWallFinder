//
//  FeatureCloud.swift
//  LiveWallFinder
//
//  Created by Rolf Lakaemper on 7/27/17.
//  Copyright © 2017 Rolf Lakaemper. All rights reserved.
//

import Foundation
import ARKit

/// Feature Cloud: a thread safe collector of feature points
/// Allows concurrent reads, but blocks writing vs reading concurrencies
/// as well as writing vs writing concurrencies
///
public class FeatureCloud{
    // parallel queue handling data access.
    // Writing: async, barrier=true, reading: sync
    let fcQueue = DispatchQueue(label: "MyArrayQueue", attributes: .concurrent)
    //
    private let MAXNUMFEATUREPOINTS = 1000000
    private var recentCloud = ARPointCloud()
    private var recentFeaturePoints = [FeaturePoint]()
    private var allFeaturePoints = [FeaturePoint]()
    private var updateListeners = [FeaturePointUpdateListener]()
    private var oldTime: TimeInterval = 0.0
    // voxelization (to equalize distribution): hash set
    var isResolutionUnits = false
    var resolution = Float(0.0)
    private var voxelHash: Set<FeaturePoint>
    
    
    // -----------------------------------------------------------
    
    /// init
    init(){
        voxelHash = Set<FeaturePoint>(minimumCapacity: MAXNUMFEATUREPOINTS * 2)
    }
    
    /// init from [FeaturePoints]
    init(points: [FeaturePoint]){
        voxelHash = Set<FeaturePoint>(minimumCapacity: MAXNUMFEATUREPOINTS * 2)
        allFeaturePoints = points
    }
    
    /// setEqualDistribution: if true, the data is voxelized
    /// Voxelization is done by quantization and hashing, no octree
    /// involved here. This is doable if the amount of data is manageable
    func setEqualDistibution(equal: Bool, resolution: Float){
        self.isResolutionUnits = equal
        self.resolution = resolution
        if (!equal){
            return
        }
        if (allFeaturePoints.count == 0){
            return
        }
        recentFeaturePoints.removeAll()
        var quantizedPoints = [FeaturePoint]()
        fcQueue.async(flags: .barrier) {
            for fp in self.allFeaturePoints{
                var fp1 = fp
                fp1.convertToResolutionUnits(resolution: resolution)
                let check = self.voxelHash.insert(fp1)
                if (check.inserted){
                    quantizedPoints.append(fp1)
                }
            }
            self.allFeaturePoints = quantizedPoints
        }
        //
        // inform all listeners about the update
        // this will perform AFTER the points are updated
        // due to the previous barrier flag
        fcQueue.async(){
            for listener in self.updateListeners{
                listener.onFeaturePointsUpdated(featureCloud: self)
            }
        }
    }
    
    /// Add Points: add feature points from current frame to feature cloud
    /// Thread safe: runs as async barriered process in queue
    /// - Parameter points: point cloud
    /// -------------------------------
    func updatePoints(points arPts: ARPointCloud, time: TimeInterval){
        if(time - oldTime > 1.0) {
            oldTime = time
            fcQueue.async(flags: .barrier) {
                // empty cloud
                if (arPts.count == 0){
                    return
                }
                //
                // duplicate cloud
                if (arPts == self.self.recentCloud){
                    return
                } else {
                    self.recentCloud = arPts
                }
                
                //
                // we are fine. Convert and copy.
                self.recentFeaturePoints.removeAll()
                for i in 0..<arPts.count {
                    var fp = FeaturePoint(x: arPts.points[i][0], y:  arPts.points[i][1], z:  arPts.points[i][2])
                    if (self.isResolutionUnits){
                        fp.convertToResolutionUnits(resolution: self.resolution)
                        let check = self.voxelHash.insert(fp)
                        if (check.inserted){
                            self.recentFeaturePoints.append(fp)
                        }
                    } else {
                        self.recentFeaturePoints.append(fp)
                    }
                }
                if (self.recentFeaturePoints.count + self.allFeaturePoints.count < self.MAXNUMFEATUREPOINTS){
                    self.allFeaturePoints += self.recentFeaturePoints
                }
            }
            //
            // inform all listeners about the update
            // this will perform AFTER the points are updated
            // due to the previous barrier flag
            fcQueue.async(){
                for listener in self.updateListeners{
                    listener.onFeaturePointsUpdated(featureCloud: self)
                }
            }
        }
    }
    
    /// addUpdateListener: register a FeaturePointUpdateListener
    /// - Parameter listener: the listener
    func addUpdateListener(listener: FeaturePointUpdateListener){
        updateListeners.append(listener)
    }
    
    
    
    // MARK: Output Routines --------------------------------------------------------------------------------------
    
    
    /// info: print info about feature cloud
    /// Thread safe
    /// ------------------------------------
    func info(){
        fcQueue.sync() {
            print("Feature Cloud: total size = \(allFeaturePoints.count), recently added points = \(recentFeaturePoints.count)")
        }
    }
    
    /// Visualize Feature Cloud
    /// Thread safe
    /// - Parameters visualizer: Visualizer
    func visualize(visualizer viz: Visualizer){
        fcQueue.sync(){
            let pts = toDoubleArray();
            viz.addPointCloud(points: pts)
        }
    }
    
    // MARK: Cloud Access ------------------------------------------------------------------------------------------
    
    /// Transform = rotate (first) and translate
    /// Thread safe
    /// - Parameter rotAxis: rotation axis
    /// - Parameter rotAngle: rotation angle, in degrees
    /// - Parameter translate: rotation axis
    /// - Returns: ransformed feature cloud (deep copy)
    func transform(rotAxis: GLKVector3 = GLKVector3Make(0,1,0), rotAngle: Float = 0, translate: GLKVector3 = GLKVector3Make(0,0,0))->FeatureCloud{
        let radAngle = rotAngle / 180 * Float.pi
        let q = GLKQuaternionMakeWithAngleAndAxis(radAngle, rotAxis.x, rotAxis.y, rotAxis.z)
        let M = GLKMatrix4MakeWithQuaternion(q)
        let rotCloud = FeatureCloud()
        //
        fcQueue.sync(){
            for f in allFeaturePoints{
                var f1 = f
                if (isResolutionUnits){
                    f1.convertFromResolutionUnits(resolution: self.resolution)
                }
                let trf = GLKMatrix4MultiplyVector4(M, GLKVector4Make(f1.x, f1.y, f1.z, 1))
                let fp = FeaturePoint(x: trf.x, y: trf.y, z: trf.z)
                rotCloud.allFeaturePoints.append(fp)
            }
        }
        
        // TODO: TRANSLATE
        
        return(rotCloud)
    }
    
    
    
    /// Convert to Double array [x,y,z,x,y,z,...]
    /// Thread safe
    func toDoubleArray()->[Double]{
        var allPts = [Double]()
        allPts.reserveCapacity(allFeaturePoints.count * 3)
        fcQueue.sync {
            //
            for f in allFeaturePoints{
                var f1 = f
                if (isResolutionUnits){
                    f1.convertFromResolutionUnits(resolution: self.resolution)
                }
                allPts.append(Double(f1.x))
                allPts.append(Double(f1.y))
                allPts.append(Double(f1.z))
            }
        }
        return(allPts)
    }
    
    /// Project to XZ plane and convert to 2D Double array [x,z,x,z,...]
    /// Thread safe
    /// - returns: Double [x,z,x,z,....]
    func to2DDoubleArrayXZ()->[Double]{
        var allPts = [Double]()
        allPts.reserveCapacity(allFeaturePoints.count * 2)
        fcQueue.sync {
            //
            for f in allFeaturePoints{
                var f1 = f
                if (isResolutionUnits){
                    f1.convertFromResolutionUnits(resolution: self.resolution)
                }
                allPts.append(Double(f1.x))
                allPts.append(Double(f1.z))
            }
        }
        return(allPts)
    }
    
    /// Project to 1D Axis (creating bins)
    /// Thread safe
    /// - returns:
    func projectTo1D(resolution: Double, axis: String)->[Double]{
        var cells = [Double]()
        fcQueue.sync {
            //
            // find min/max
            var minV = 1e20 as Double
            var maxV = -1e20 as Double
            switch (axis){
            case "X":
                for f in allFeaturePoints{
                    minV = Double.minimum(minV, Double(f.x))
                    maxV = Double.maximum(maxV, Double(f.x))
                }
            case "Y":
                for f in allFeaturePoints{
                    minV = Double.minimum(minV, Double(f.y))
                    maxV = Double.maximum(maxV, Double(f.y))
                }
            case "Z":
                for f in allFeaturePoints{
                    minV = Double.minimum(minV, Double(f.z))
                    maxV = Double.maximum(maxV, Double(f.z))
                }
            default:
                return
            }
            if (isResolutionUnits){
                minV = minV * Double(self.resolution)
                maxV = maxV * Double(self.resolution)
            }
            //
            let nCells = Int((maxV-minV)/resolution) + 1
            cells = [Double](repeating: 0, count: nCells)
        
            switch(axis){
            case "X":
                for f in allFeaturePoints {
                    var f1 = f
                    if (isResolutionUnits){
                        f1.convertFromResolutionUnits(resolution: self.resolution)
                    }
                    let cell = Int((Double(f1.x) - minV)/resolution)
                    cells[cell] = cells[cell] + 1
                }
            case "Y":
                for f in allFeaturePoints {
                    var f1 = f
                    if (isResolutionUnits){
                        f1.convertFromResolutionUnits(resolution: self.resolution)
                    }
                    let cell = Int((Double(f1.y) - minV)/resolution)
                    cells[cell] = cells[cell] + 1
                }
            case "Z":
                for f in allFeaturePoints {
                    var f1 = f
                    if (isResolutionUnits){
                        f1.convertFromResolutionUnits(resolution: self.resolution)
                    }
                    let cell = Int((Double(f1.z) - minV)/resolution)
                    cells[cell] = cells[cell] + 1
                }
            default:
                return
            }
        }
        return(cells)
    }
    
    /// get number of points: point count
    /// - returns: count of all and recent points
    func getNumberOfPoints()->(all: Int, recent: Int){
        var numAll = 0
        var numRecent = 0
        fcQueue.sync {
            numAll = allFeaturePoints.count
            numRecent = recentFeaturePoints.count
        }
        return(numAll, numRecent)
    }
    
    /// Get Bounding Box
    func getBoundingBox()->(xMin: Float, yMin: Float, zMin: Float, xMax: Float, yMax: Float, zMax: Float){
        var xMin = Float.greatestFiniteMagnitude
        var yMin = Float.greatestFiniteMagnitude
        var zMin = Float.greatestFiniteMagnitude
        var xMax = Float.leastNormalMagnitude
        var yMax = Float.leastNormalMagnitude
        var zMax = Float.leastNormalMagnitude
        fcQueue.sync {
            for fp in allFeaturePoints{
                if (fp.x < xMin){xMin = fp.x}
                if (fp.y < yMin){yMin = fp.y}
                if (fp.z < zMin){zMin = fp.z}
                if (fp.x > xMax){xMax = fp.x}
                if (fp.y > yMax){yMax = fp.y}
                if (fp.z > zMax){zMax = fp.z}
            }
        }
        if (isResolutionUnits){
            xMin = xMin * resolution
            yMin = yMin * resolution
            zMin = zMin * resolution
            xMax = xMax * resolution
            yMax = yMax * resolution
            zMax = zMax * resolution
            
        }
        return((xMin, yMin, zMin, xMax, yMax, zMax))
    }
    
    /// Get all points: thread safe copy of pointset
    func copyAllPoints()->[FeaturePoint]{
        var cp = [FeaturePoint]()
        fcQueue.sync {
            cp.reserveCapacity(allFeaturePoints.count)
            for f in allFeaturePoints{
                var f1 = f
                if (isResolutionUnits){
                    f1.convertFromResolutionUnits(resolution: self.resolution)
                }
                cp.append(f1)
            }
        }
        return(cp)
    }
}





