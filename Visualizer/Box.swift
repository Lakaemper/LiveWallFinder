//
//  Box.swift
//  VizTest
//
//  Created by Rolf Lakaemper on 7/20/17.
//  Copyright © 2017 Rolf Lakaemper. All rights reserved.
//

import Foundation
import SceneKit


/**
 Initializer
 */
internal class Box : Drawable {
    internal init(center: SCNVector3 = SCNVector3Zero, radii: SCNVector3 = SCNVector3(1,1,1), material mat: SCNMaterial = Materials.getColor("red")){
        super.init()
        geometry = SCNBox(width: CGFloat(radii.x), height: CGFloat(radii.y), length: CGFloat(radii.z), chamferRadius: 0)
        geometry.materials = [mat]
        node = SCNNode(geometry: geometry)
        node.localTranslate(by: center)
    }
}
