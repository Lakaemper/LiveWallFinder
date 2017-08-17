//
//  PointCloud.swift
//  GeometryTest
//
//  Created by Rolf Lakaemper on 7/17/17.
//  Copyright © 2017 Rolf Lakaemper. All rights reserved.
//

import Foundation
import SceneKit

internal class VizPointCloud : Drawable{
    
    internal init(points pts: [Double], material mat: SCNMaterial){
        super.init()
        //
        let numPoints = pts.count / 3
        let indices: [Int32] = Array(Int32(0) ... Int32(numPoints))
        var vert = [SCNVector3](repeating: SCNVector3Zero, count: numPoints)
        for i in 0...numPoints-1{
            vert[i] = SCNVector3(pts[i*3], pts[i*3+1], pts[i*3+2])
        }
        let source = SCNGeometrySource(vertices: vert)
        let element = SCNGeometryElement(indices: indices, primitiveType: .point)
        geometry = SCNGeometry(sources: [source], elements: [element])
        geometry.materials = [mat]
        node = SCNNode()
        node.geometry = geometry
    }
}

