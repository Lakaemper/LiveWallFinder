//
//  Visualizer.swift
//  GeometryTest
//
//  Created by Rolf Lakaemper on 7/17/17.
//  Copyright © 2017 Rolf Lakaemper. All rights reserved.
//

import Foundation
import SceneKit
import SpriteKit

public class Visualizer:  UIViewController, SCNSceneRendererDelegate
    
    
{
    // enumeration to distinguish visualizer elements
    // used e.g. in 'clear(_:) function
    public enum VizElement{
        case All, PointCloud, Marker, CoordinateCross
    }
    let vizElementDictionary: [VizElement:String] = [.All:"All", .PointCloud:"PointCloud", .Marker:"Marker", .CoordinateCross:"CoordinateCross"]
    
    private var scnScene: SCNScene!
    private var cameraNode: SCNNode!
    private var prevTime: Double = 0.0
    private var defaultMaterial: SCNMaterial!
    private var geomNode: SCNNode!
    private var theView: SCNView!
    private var autoRotateSpeed = 0.0
    private var textHUD: VizTextHUD!
    static var debugCount = 0

    
    
    
    /**
     Initializer
     */
    init(_ view: SCNView){
        super.init(nibName: nil, bundle: nil)
        _ = Materials()
        defaultMaterial = Materials.material!.greenEmission
        //
        // connection to view
        self.theView = view
        scnScene = SCNScene()
        view.scene = scnScene
        view.backgroundColor = UIColor.black
        //
        // camera
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 5, y: 5, z: 5)
        cameraNode.look(at: SCNVector3Zero)
        scnScene.rootNode.addChildNode(cameraNode)
        view.allowsCameraControl = true
        //
        // lighting
        view.autoenablesDefaultLighting = false
        //
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLight.LightType.ambient
        ambientLightNode.light!.color = UIColor(white: 0.67, alpha: 1.0)
        scnScene.rootNode.addChildNode(ambientLightNode)
        //
        let directionalLight = SCNLight()
        directionalLight.type = SCNLight.LightType.directional
        directionalLight.color = UIColor.white
        let myDirectLightNode = SCNNode()
        myDirectLightNode.light = directionalLight
        myDirectLightNode.orientation = SCNQuaternion(x: 1, y: 1, z: 1, w: 0.2)
        scnScene.rootNode.addChildNode(myDirectLightNode)
        //
        // General geometry node. Add all geometries to this node, as this is the
        // node that is handled by the 'clear()' command
        geomNode = SCNNode()
        scnScene.rootNode.addChildNode(geomNode)
        //
        // etc
        view.delegate = self
        view.showsStatistics = true
        view.play(self)
        //
        // Text HUD Overlay
        textHUD = VizTextHUD(theView: theView)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    /**
     Animation
     */
    public func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let diffTime = time-prevTime
        prevTime = time
        //
        // Auto Rotation
        if (autoRotateSpeed != 0.0){
            var qgl = GLKQuaternionMakeWithAngleAndAxis(Float(diffTime) * 3, 0, 1, 0)
            var q = SCNQuaternion()
            q.w = qgl.w
            q.x = qgl.x
            q.y = qgl.y
            q.z = qgl.z
            geomNode.rotate(by: q, aroundTarget: SCNVector3Zero)
        }
    }
    
    // ================================================================================================
    
    
    // MARK: General --------------------------------------------------------------------
    
    /// Set Background Color
    public func setBackground(color: UIColor){
        theView.backgroundColor = color
    }
    
    // MARK: Animation ------------------------------------------------------------------
    
    /// Set Auto Rotation
    public func setAutoRotation(speed: Double){
        autoRotateSpeed = speed
    }
    
    // MARK: Camera ---------------------------------------------------------------------
    
    /// Set Camera
    public func setCamera(position pos: SCNVector3, lookAt at: SCNVector3){
        cameraNode.position = pos
        cameraNode.look(at: at)
    }
    
    // MARK: Drawing --------------------------------------------------------------------
    /**
     Clear visual elements
     */
    public func clear(_ element: VizElement = .All){
        if (element == .All){
            geomNode.enumerateChildNodes { (node, stop) -> Void in
                node.removeFromParentNode()
            }
        } else {
            geomNode.enumerateChildNodes { (node, stop) -> Void in
                if node.name == vizElementDictionary[element]{
                    node.removeFromParentNode()
                }
            }
        }
    }
    
    /**
     Line Drawing
     */
    public func addLine(from v1: SCNVector3, to v2: SCNVector3, material mat: SCNMaterial = Materials.getColor("whiteEmission") ){
        let line = Line(from: v1, to: v2, mat)
        geomNode.addChildNode(line.node)
    }
    
    /**
     Coordinate Cross
     */
    public func addCoordinateCross(origin org: SCNVector3 = SCNVector3Zero, length len: Float = 1){
        let x = SCNVector3(org.x + len,org.y,org.z)
        let y = SCNVector3(org.x, org.y+len,org.z)
        let z = SCNVector3(org.x, org.y, org.z+len)
        addLine(from: org, to: x, material: Materials.material!.redEmission)
        addLine(from: org, to: y, material: Materials.material!.greenEmission)
        addLine(from: org, to: z, material: Materials.material!.blueEmission)
    }
    
    /**
     Point Cloud
     */
    public func addPointCloud(points pts: [Double], material mat: SCNMaterial = Materials.getColor("greenEmission")){
        if (pts.count > 0){
            let pc = VizPointCloud(points: pts, material: mat)
            geomNode.addChildNode(pc.node)
        }
    }
    
    /**
     Mark Point
     */
    public func markPoint(position pos: SCNVector3, material: SCNMaterial = Materials.getColor("redMark"), markRadius: Float = 0.04){
        let sphereGeom = SCNSphere()
        sphereGeom.radius = CGFloat(markRadius);
        sphereGeom.materials = [material]
        let sphereNode = SCNNode(geometry: sphereGeom)
        sphereNode.localTranslate(by: pos)
        geomNode.addChildNode(sphereNode)
    }
    
    
    /**
     Box
     */
    public func addBox(center: SCNVector3 = SCNVector3Zero, radii: SCNVector3 = SCNVector3(1,1,1), material: SCNMaterial = Materials.getColor("red")){
        let box = Box(center: center, radii: radii, material: material)
        geomNode.addChildNode(box.node)
    }
    
    /**
     VoxelCloud
     */
    public func addVoxelCloud(cloud: FeatureCloud, material: SCNMaterial = Materials.getColor("red")){
        let cld = VizVoxelCloud(voxels: cloud, material: material)
        geomNode.addChildNode(cld.node)
    }
    
    /**
     Plane
     */
    public func addPlane(center: SCNVector3 = SCNVector3Zero,
                         normal: SCNVector3 = SCNVector3(0,0,1),
                         radii: SCNVector3 = SCNVector3(1,1,0),
                         xDirection: SCNVector3 = SCNVector3(1,1,1),
                         material: SCNMaterial = Materials.getColor("red", 0.5)){
        
        let plane = Plane(center: center, normal: normal, radii: radii, xDirection: xDirection, material: material)
        geomNode.addChildNode(plane.node)
    }
    
    // MARK: Text output ------------------------------------------------------------------
    
    /// HUD Print: print on HUD overlay, prints (or appends) text at cursor line position
    /// and increments cursorLine thereafter
    /// - Parameter text: the text string
    /// - Parameter atLine: cursorLine, default = -1 = current cursorLine
    /// - Parameter append: switch between print and append
    func print(text txt:String, atLine line: Int = -1, append: Bool = false){
        textHUD.print(text: txt, atLine: line, append: append)
    }
}















