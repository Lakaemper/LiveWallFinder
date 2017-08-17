//
//  VizVoxelCloud.swift
//  LiveWallFinder
//
//  Created by Rolf Lakaemper on 8/17/17.
//  Copyright © 2017 Rolf Lakaemper. All rights reserved.
//

import Foundation
import SceneKit

class VizVoxelCloud: Drawable{
    
    init(voxels vc: FeatureCloud, material mat: SCNMaterial = Materials.getColor("red")){
        super.init()
        node = SCNNode(geometry: geometry)
        //
        // FeatureCloud must be voxelized. If not, just return.
        if (!vc.isResolutionUnits){
            return
        }
        //
        // for now, just draw a box for each point. Horribly slow, I presume.
        let radius = vc.resolution / 2
        for f in vc.copyAllPoints(){
            geometry = SCNBox(width: CGFloat(radius), height: CGFloat(radius), length: CGFloat(radius), chamferRadius: 0)
            geometry.materials = [mat]
            let center = SCNVector3(f.x, f.y, f.z)
            let boxNode = SCNNode(geometry: geometry)
            boxNode.localTranslate(by: center)
            node.addChildNode(boxNode)
        }
    }
}
