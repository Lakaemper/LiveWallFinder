//
//  ARTopView.swift
//  LiveWallFinder
//
//  Created by Rolf Lakaemper on 7/27/17.

import ARKit
import Foundation
import SceneKit

class ARTopView: ARSCNView, ARSCNViewDelegate {
    
    var featureCloud: FeatureCloud?
    
    // ----------------------------------------------------------------------------------
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        print("Initializing ARView")
        //
        // set delegate
        self.delegate = self
        //
        // Create and run a session configuration
        let configuration = ARWorldTrackingSessionConfiguration()
        configuration.planeDetection = .horizontal
        self.session.run(configuration)
        self.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
    }
    
    
    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
            //
            // update feature points
            guard let featurePoints = session.currentFrame?.rawFeaturePoints else {
                return
            }
            if (featureCloud != nil){
                featureCloud!.updatePoints(points: featurePoints, time: time)
            }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .notAvailable:
            print("Tracking not available")
        case .limited:
            print("Tracking is Limited")
        case .normal:
            print("Tracking is Normal")
        }
    }
    
    func session(_ session: ARSession, didAdd: [ARAnchor]){
        print("JHGJHGJHGJHGJHGJHGJHGJHGJHGJHGJHGJHGJHG")
    }
    
    
    
    
    
}

