//
//  FPRawView.swift
//  LiveWallFinder
//
//  Created by Rolf Lakaemper on 7/28/17.
//  Copyright © 2017 Rolf Lakaemper. All rights reserved.
//

import Foundation
import SceneKit

class FPRawView: SCNView, FeaturePointUpdateListener {
    
    var viz: Visualizer!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        print("Initializing Raw View")
    }
    
    // MARK: FeaturePointUpdateListener Implementation ----------
    
    /// callback function for featureCloud update
    func onFeaturePointsUpdated(featureCloud: FeatureCloud) {
        featureCloud.info()
        viz.clear()
        viz.addPointCloud(points: featureCloud.toDoubleArray())
    }
    
}
