//
//  Materials.swift
//  GeometryTest
//
//  Created by Rolf Lakaemper on 7/17/17.
//  Copyright © 2017 Rolf Lakaemper. All rights reserved.
//

import Foundation
import SceneKit

public class Materials{
    // singleton
    static var material: Materials?
    //
    //
    // SCN materials
    public var redEmission, greenEmission, blueEmission, whiteEmission: SCNMaterial
    public var red, green, blue, white: SCNMaterial
    public var redMark, greenMark, blueMark, whiteMark: SCNMaterial
    
    public init(){
        redEmission = SCNMaterial()
        redEmission.ambient.contents = UIColor.black
        redEmission.diffuse.contents = UIColor.black
        redEmission.emission.contents = UIColor.red
        
        greenEmission = SCNMaterial()
        greenEmission.ambient.contents = UIColor.black
        greenEmission.diffuse.contents = UIColor.black
        greenEmission.emission.contents = UIColor.green
        
        blueEmission = SCNMaterial()
        blueEmission.ambient.contents = UIColor.black
        blueEmission.diffuse.contents = UIColor.black
        blueEmission.emission.contents = UIColor.blue
        
        whiteEmission = SCNMaterial()
        whiteEmission.ambient.contents = UIColor.black
        whiteEmission.diffuse.contents = UIColor.black
        whiteEmission.emission.contents = UIColor.white
        
        red = SCNMaterial()
        red.lightingModel = SCNMaterial.LightingModel.lambert
        red.diffuse.contents = UIColor.red
        
        green = SCNMaterial()
        green.lightingModel = SCNMaterial.LightingModel.lambert
        green.diffuse.contents = UIColor.green
        
        blue = SCNMaterial()
        blue.lightingModel = SCNMaterial.LightingModel.lambert
        blue.diffuse.contents = UIColor.blue
        
        white = SCNMaterial()
        white.lightingModel = SCNMaterial.LightingModel.lambert
        white.diffuse.contents = UIColor.white
        
        redMark = SCNMaterial()
        redMark.lightingModel = SCNMaterial.LightingModel.lambert
        redMark.diffuse.contents = UIColor.red
        
        greenMark = SCNMaterial()
        greenMark.lightingModel = SCNMaterial.LightingModel.lambert
        greenMark.diffuse.contents = UIColor.green
        
        blueMark = SCNMaterial()
        blueMark.lightingModel = SCNMaterial.LightingModel.lambert
        blueMark.diffuse.contents = UIColor.blue
        
        whiteMark = SCNMaterial()
        whiteMark.lightingModel = SCNMaterial.LightingModel.lambert
        whiteMark.diffuse.contents = UIColor.white
        //
        // add animation
        let animation = CABasicAnimation(keyPath: "transparency")
        animation.fromValue = 0.0
        animation.toValue = 1.0
        animation.duration = 0.5
        animation.autoreverses = true
        animation.repeatCount = .infinity
        redMark.addAnimation(animation, forKey: nil)
        greenMark.addAnimation(animation, forKey: nil)
        blueMark.addAnimation(animation, forKey: nil)
        whiteMark.addAnimation(animation, forKey: nil)
        
        Materials.material = self
    }
    
    public static func getColor(_ col:String, _ alpha: Float = 1.0) -> SCNMaterial{
        var mat: SCNMaterial
        switch (col){
        case "redEmission": mat = Materials.material!.redEmission
        case "greenEmission": mat = Materials.material!.greenEmission
        case "blueEmission": mat = Materials.material!.blueEmission
        case "whiteEmission": mat = Materials.material!.whiteEmission
        case "red": mat = Materials.material!.red
        case "green": mat = Materials.material!.green
        case "blue": mat = Materials.material!.blue
        case "white": mat = Materials.material!.white
        case "redMark": mat = Materials.material!.redMark
        case "greenMark": mat = Materials.material!.greenMark
        case "blueMark": mat = Materials.material!.blueMark
        case "whiteMark": mat = Materials.material!.whiteMark
            
        default:
            mat = Materials.material!.redEmission
        }
        mat.transparency = CGFloat(alpha)
        return(mat)
    }
    
    public static func getColor(r: Float, g: Float, b: Float, _ alpha: Float = 1.0) -> SCNMaterial{
        let mat = SCNMaterial()
        mat.lightingModel = SCNMaterial.LightingModel.lambert
        mat.diffuse.contents = UIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1)
        mat.transparency = CGFloat(alpha)
        return(mat)
    }
}




