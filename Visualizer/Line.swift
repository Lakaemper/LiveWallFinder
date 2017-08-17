//
//  Line.swift
//  GeometryTest
//
//  Created by Rolf Lakaemper on 7/17/17.
//  Copyright © 2017 Rolf Lakaemper. All rights reserved.
//

import Foundation
import SceneKit


/**
 Initializer
 */
internal class Line : Drawable {
    internal init(from v1: SCNVector3, to v2: SCNVector3, _ mat: SCNMaterial){
        super.init()
        //
        let indices: [Int32] = [0, 1]
        let source = SCNGeometrySource(vertices: [v1, v2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        geometry = SCNGeometry(sources: [source], elements: [element])
        geometry.materials = [mat]
        node = SCNNode()
        node.geometry = geometry
        
    }
}



