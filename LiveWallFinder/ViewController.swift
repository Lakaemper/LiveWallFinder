//
//  ViewController.swift
//  LiveWallFinder
//
//  Created by Rolf Lakaemper on 7/27/17.
//  Copyright © 2017 Rolf Lakaemper. All rights reserved.
//

import UIKit
import SceneKit
import ARKit


class ViewController: UIViewController {

    
    
    @IBOutlet weak var arView: ARTopView!
    @IBOutlet weak var rawView: FPRawView!
    
    var viz: Visualizer!
    let featureCloud = FeatureCloud()
    let wallFinder = WallFinder()
    
    // ----------------------------------------------------------
    /// View Did Load: main entry point
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let resolution: Float = 0.05
        print("Feature Cloud Voxelized with resolution \(resolution)")
        featureCloud.setEqualDistibution(equal: true, resolution: resolution)
        //
        // init visualizer and connect it to the bottom view
        viz = Visualizer(rawView)
        viz.addCoordinateCross()
        //
        // add feature cloud to ARViewer. ARViewer updates the
        // cloud on rendering.
        arView!.featureCloud = featureCloud
        //
        // set the WallFinder's visualizer
        wallFinder.viz = viz
        //
        // register wall finder to featureCloud.
        // Feature cloud calls wall finder on update.
        // In turn wallFinder processes cloud and displays it
        featureCloud.addUpdateListener(listener: wallFinder)
    }
}

