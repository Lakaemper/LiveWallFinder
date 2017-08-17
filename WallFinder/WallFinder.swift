//
//  WallFinder.swift
//  LiveWallFinder
//
//  Created by Rolf Lakaemper on 7/28/17.
//  Copyright © 2017 Rolf Lakaemper. All rights reserved.
//

import Foundation
import SceneKit

class WallFinder: FeaturePointUpdateListener {
    var viz: Visualizer!
    var previousAngle = -1.0
    var fromAngle = 0.0
    var toAngle = 90.0
    var diffAngle = 8.0
    var angleCount = 0
    var mustAnalyseDirection = true
    var frameCount = 0
    //
    // PARAMETERS
    // bin-size of 1D vectors
    let RESOLUTION = 0.10
    // adaptice precision for axis alignment, counter
    let ANGLECOUNTTHRESH = 8
    // 1D lowpass kernel
    let KERNEL = [1.0,2.0,3.0,2.0,1.0]
    // threshold for 1D noise
    let NOISETHRESH = 20.0
    
    // ------------------------------------------------------------------
    /// init
    init(){
        
    }
    
    // MARK: FeaturePointUpdateListener Implementation ----------
    
    // ------------------------------------------------------------------
    /// callback function for featureCloud update
    func onFeaturePointsUpdated(featureCloud: FeatureCloud) {
        frameCount = frameCount + 1
        //
        // Step 1: Axis alignment
        let rotatedCloud = alignToAxes(featureCloud: featureCloud)
        //
        // Step 2: project to X, Y and Z
        var projectX = rotatedCloud.projectTo1D(resolution: RESOLUTION, axis: "X")
        var projectY = rotatedCloud.projectTo1D(resolution: RESOLUTION, axis: "Y")
        var projectZ = rotatedCloud.projectTo1D(resolution: RESOLUTION, axis: "Z")
        //
        // Step 3: find X, Y, Z boundaries
        let boundaries = findBoundaries(pX: &projectX, pY: &projectY, pZ: &projectZ, rotatedCloud: rotatedCloud)
        //
        // Step 4: Visualize
        //visualize(boundaries: boundaries, rotatedCloud: rotatedCloud )
        
        if (boundaries.validResult){
            
            let bndr = (boundaries.minX, boundaries.minY, boundaries.minZ, boundaries.maxX, boundaries.maxY, boundaries.maxZ)
            var walls = applyWallFilter(featureCloud: rotatedCloud, boundaries: bndr, distThresh: Float(0.3))
            viz.clear()
            viz.addCoordinateCross()
            
            //viz.addPointCloud(points: walls[0].toDoubleArray(), material: Materials.getColor("redEmission"))
            //viz.addPointCloud(points: walls[1].toDoubleArray(), material: Materials.getColor("redEmission"))
            //viz.addPointCloud(points: walls[2].toDoubleArray(), material: Materials.getColor("redEmission"))
            //viz.addPointCloud(points: walls[3].toDoubleArray(), material: Materials.getColor("redEmission"))
            viz.addPointCloud(points: walls[4].toDoubleArray(), material: Materials.getColor("greenEmission"))
            viz.addPointCloud(points: walls[5].toDoubleArray(), material: Materials.getColor("whiteEmission"))
            var f = walls[0]
            f.setEqualDistibution(equal: true, resolution: 0.2)
            viz.addVoxelCloud(cloud: f, material: Materials.getColor("red"))
            f = walls[1]
            f.setEqualDistibution(equal: true, resolution: 0.2)
            viz.addVoxelCloud(cloud: f, material: Materials.getColor("red"))
            f = walls[2]
            f.setEqualDistibution(equal: true, resolution: 0.2)
            viz.addVoxelCloud(cloud: f, material: Materials.getColor("red"))
            f = walls[3]
            f.setEqualDistibution(equal: true, resolution: 0.2)
            viz.addVoxelCloud(cloud: f, material: Materials.getColor("red"))
            
            
            
        } else {
            viz.clear()
            viz.addCoordinateCross()
            //viz.addPointCloud(points: rotatedCloud.toDoubleArray(), material: Materials.getColor("whiteEmission"))
            rotatedCloud.setEqualDistibution(equal: true, resolution: featureCloud.resolution)
            viz.addVoxelCloud(cloud: rotatedCloud)
        }
        //
        // Debug Info
        viz.print(text: "\(frameCount) frames, voxelized = \(featureCloud.isResolutionUnits)", atLine: 0)
        let num = featureCloud.getNumberOfPoints()
        viz.print(text: "numPoints: \(num.all) ")
        viz.print(text: "wall angle: \(previousAngle), resolution (deg):  \(diffAngle)")
        if (diffAngle > 0){
            viz.print(text: "precision count: \(angleCount)")
        } else {
            viz.print(text: "Locked in.")
        }
    }
    
    // ------------------------------------------------------------------
    /// Axis Alignment: Auto adaptive alignment to XZ axes
    /// - returns: rotated feature cloud in 3D and 2D
    private func alignToAxes(featureCloud: FeatureCloud)->(FeatureCloud){
        // Project to XZ Double[x,z,x,z,...]
        // TODO: 2D PROJECTION IS UNNECESSARY!
        let pts2 = featureCloud.to2DDoubleArrayXZ()
        //
        // Find Dominant direction
        if (mustAnalyseDirection){
            var dd = Analysis2D.findDominantDirection(points: pts2, from: fromAngle, to: toAngle, angStep: diffAngle)
            // module: smallest angle
            dd = dd.truncatingRemainder(dividingBy: 90)
            // track angle: if angle stabilized, increase precision
            if (dd == previousAngle){
                angleCount = angleCount - 1
            } else {
                angleCount = ANGLECOUNTTHRESH
                previousAngle = dd
            }
            if (angleCount == 0){
                if (diffAngle > 1.0){
                    fromAngle = dd - diffAngle * 2
                    toAngle = dd + diffAngle * 2
                    diffAngle = diffAngle / 2
                    angleCount = ANGLECOUNTTHRESH
                } else {
                    diffAngle = 0.0
                    mustAnalyseDirection = false
                }
            }
        }
        //
        // Rotate (3D and 2D)
        let rotatedCloud = featureCloud.transform(rotAxis: GLKVector3Make(0, 1, 0), rotAngle: Float(-previousAngle), translate: GLKVector3Make(0, 0, 0))
        return(rotatedCloud)
    }
    
    
    
    // ------------------------------------------------------------------
    /// Find Boundaries: Core Wall Finding routine
    func findBoundaries(pX: inout [Double], pY: inout [Double], pZ: inout [Double], rotatedCloud: FeatureCloud) ->
        (validResult: Bool, minX: Double, minY: Double, minZ: Double, maxX: Double, maxY: Double, maxZ: Double){
            //
            // WALLFINDING
            // Find peaks in XZ projections
            var kernel = KERNEL
            Analysis1D.normalizeLocal(data: &kernel)
            //
            pX = Analysis1D.convolute(data: pX, kernel: kernel)
            pY = Analysis1D.convolute(data: pY, kernel: kernel)
            pZ = Analysis1D.convolute(data: pZ, kernel: kernel)
            Analysis1D.threshLocal(data: &pX, thresh: NOISETHRESH)
            Analysis1D.threshLocal(data: &pY, thresh: NOISETHRESH)
            Analysis1D.threshLocal(data: &pZ, thresh: NOISETHRESH)
            //
            let peakXmin = Analysis1D.findPeak(data: pX, location: "first")
            let peakZmin = Analysis1D.findPeak(data: pZ, location: "first")
            let peakYmin = Analysis1D.findPeak(data: pY, location: "first")
            let peakYmax = Analysis1D.findPeak(data: pY, location: "last")
            let peakXmax = Analysis1D.findPeak(data: pX, location: "last")
            let peakZmax = Analysis1D.findPeak(data: pZ, location: "last")
            //
            // are peaks conclusive?
            var wallsAreConclusive = true
            if (peakXmin.value == 0.0 || peakYmin.value == 0.0 || peakZmin.value == 0.0){
                wallsAreConclusive = false
            }
            if (peakXmin.index >= peakXmax.index || peakYmin.index >= peakYmax.index || peakZmin.index >= peakZmax.index){
                wallsAreConclusive = false
            }
            if (wallsAreConclusive){
                //
                // if peaks are conclusive here, compute boundaries in world coordinates
                let bb = rotatedCloud.getBoundingBox()
                let minX = Double(bb.xMin) + Double(peakXmin.index) * RESOLUTION
                let maxX = Double(bb.xMin) + Double(peakXmax.index) * RESOLUTION
                let minY = Double(bb.yMin) + Double(peakYmin.index) * RESOLUTION
                let maxY = Double(bb.yMin) + Double(peakYmax.index) * RESOLUTION
                let minZ = Double(bb.zMin) + Double(peakZmin.index) * RESOLUTION
                let maxZ = Double(bb.zMin) + Double(peakZmax.index) * RESOLUTION
                return(true,minX, minY, minZ, maxX, maxY, maxZ)
                
            } else {
                return(false,0,0,0,0,0,0)
            }
    }
    
    // ------------------------------------------------------------------
    /// Visualize
    private func visualize(boundaries:(validResult: Bool, minX: Double, minY: Double, minZ: Double, maxX: Double, maxY: Double, maxZ: Double), rotatedCloud: FeatureCloud){
        // Visualize rotated points
        viz.clear()
        viz.addCoordinateCross()
        let mat = Materials.getColor("white")
        viz.addPointCloud(points: rotatedCloud.toDoubleArray(), material: mat)
        if (boundaries.validResult){
            let centerX = (boundaries.minX + boundaries.maxX ) / 2
            let centerY = (boundaries.minY + boundaries.maxY ) / 2
            let centerZ = (boundaries.minZ + boundaries.maxZ ) / 2
            let radiusX = (boundaries.maxX - boundaries.minX ) / 2
            let radiusY = (boundaries.maxY - boundaries.minY ) / 2
            let radiusZ = (boundaries.maxZ - boundaries.minZ ) / 2
            let wallColor = "red"
            var trans = 0.3 as Float
            viz.addPlane(center: SCNVector3(centerX, centerY, boundaries.minZ), normal: SCNVector3(0,0,1), radii: SCNVector3(radiusX, radiusY, 0.0), xDirection: SCNVector3Zero, material: Materials.getColor(wallColor,trans))
            viz.addPlane(center: SCNVector3(centerX, centerY, boundaries.maxZ), normal: SCNVector3(0,0,1), radii: SCNVector3(radiusX, radiusY, 0.0), xDirection: SCNVector3Zero, material: Materials.getColor(wallColor,trans))
            viz.addPlane(center: SCNVector3(boundaries.minX, centerY,centerZ), normal: SCNVector3(1,0,0), radii: SCNVector3(radiusZ, radiusY, 0.0), xDirection: SCNVector3Zero, material: Materials.getColor(wallColor,trans))
            viz.addPlane(center: SCNVector3(boundaries.maxX, centerY,centerZ), normal: SCNVector3(1,0,0), radii: SCNVector3(radiusZ, radiusY, 0.0), xDirection: SCNVector3Zero, material: Materials.getColor(wallColor,trans))
            // Floor and Ceiling
            let color = "green"
            trans = 0.2
            viz.addPlane(center: SCNVector3(centerX, boundaries.minY, centerZ), normal: SCNVector3(0,1,0), radii: SCNVector3(radiusX, radiusZ, 0.0), xDirection: SCNVector3Zero, material: Materials.getColor(color,trans))
            //viz.addPlane(center: SCNVector3(centerX, boundaries.maxY, centerZ), normal: SCNVector3(0,1,0), radii: SCNVector3(radiusX, radiusZ, 0.0), xDirection: SCNVector3Zero, material: Materials.getColor(color,trans))
        }
    }
    
    // -------------------------------------------------------------------------------------------------------------
    /// WallFilter: separates points of a featureCloud into 6 FeatureClouds representing floor, 4 walls, remaining
    /// (currently the ceiling is not built in)
    func applyWallFilter(featureCloud: FeatureCloud, boundaries:(minX: Double, minY: Double, minZ: Double, maxX: Double, maxY: Double, maxZ: Double), distThresh: Float)->[FeatureCloud]{
        let points = featureCloud.copyAllPoints()
        // 'nswefr' = north south west east floor remaining
        var nswefr = [[FeaturePoint]](repeating: [FeaturePoint](), count: 6)
        let minx = Float(boundaries.minX)
        let miny = Float(boundaries.minY)
        let minz = Float(boundaries.minZ)
        let maxx = Float(boundaries.maxX)
        //let maxy = Float(boundaries.maxY)
        let maxz = Float(boundaries.maxZ)
        //
        for f in points{
            var minV = 1e20 as Float
            var minI = 0
            var d = 0.0 as Float
            // north
            d = abs(f.z - minz)
            if (d < minV){
                minV = d
                minI = 0
            }
            // south
            d = abs(f.z - maxz)
            if (d < minV){
                minV = d
                minI = 1
            }
            // west
            d = abs(f.x - minx)
            if (d < minV){
                minV = d
                minI = 2
            }
            // east
            d = abs(f.x - maxx)
            if (d < minV){
                minV = d
                minI = 3
            }
            // floor
            d = abs(f.y - miny)
            if (d < minV){
                minV = d
                minI = 4
            }
            // remaining
            if (minV > distThresh){
                minI = 5
            }
            nswefr[minI].append(f)
        }
        var clouds = [FeatureCloud]()
        for i in 0...5{
            clouds.append(FeatureCloud(points: nswefr[i]))
        }
        return(clouds)
    }
}


