//
//  Plane.swift
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
internal class Plane : Drawable {
    internal init(center: SCNVector3 = SCNVector3Zero,
                  normal: SCNVector3 = SCNVector3(0,0,1),
                  radii: SCNVector3 = SCNVector3(1,1,0),
                  xDirection: SCNVector3 = SCNVector3(1,1,1),
                  material: SCNMaterial = Materials.getColor("red", 0.5)){
        super.init()
        
        //
        // geometry
        // make sure radii are positive and |normal| is > 0
        var radii = radii
        radii.x = abs(radii.x)
        radii.y = abs(radii.y)
        radii.z = abs(radii.z)
        let lenNormal = normal.x*normal.x + normal.y*normal.y + normal.z * normal.z
        if (lenNormal < 1e-5){
            print("Warning (Visualizer, Plane.init): normal == 0. Plane will not be created.")
            return
        }
        
        let pGeometry = SCNPlane(width: CGFloat(radii.x * 2.0), height: CGFloat(radii.y * 2.0))
        pGeometry.cornerRadius = CGFloat(radii.z)
        geometry = pGeometry
        
        //
        // planes get their own material, which is doubleSided (no culling)
        let planeMaterial = material.copy() as! SCNMaterial
        planeMaterial.isDoubleSided = true
        geometry.materials = [planeMaterial]
        
        //
        // Node (rotation needs an extra node, since order of
        // transformation in scenekit is translation first, then rotation!)
        let rnode = SCNNode(geometry: geometry)
        // rotate
        let gN = SCNVector3ToGLKVector3(normal)
        let gNormal = GLKVector3Normalize(gN)
        let axis = GLKVector3CrossProduct(gNormal, GLKVector3Make(0,0,1))
        let angle = -acos(GLKVector3DotProduct(gNormal, GLKVector3Make(0,0,1)))
        rnode.rotation = SCNVector4(axis.x, axis.y, axis.z, angle)
        //
        // translate
        node = SCNNode()
        node.localTranslate(by: center)
        node.addChildNode(rnode)
    }
}
