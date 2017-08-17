//
//  VizTextHUD.swift
//  LiveWallFinder
//
//  Created by Rolf Lakaemper on 8/1/17.
//  Copyright © 2017 Rolf Lakaemper. All rights reserved.
//

import Foundation
import SpriteKit
import SceneKit

class VizTextHUD{
    //
    let HUDMARGIN = 10
    var hudWidth = 0 as CGFloat
    var hudHeight = 0 as CGFloat
    var hudFontSize = 16 as CGFloat
    var numberOfRows = 0
    var overlay: SKScene
    var cursorLine = 0
    
    
    
    /// init
    /// ----------------------------------------------
    init(theView: SCNView){
        let screenSize: CGSize = theView.bounds.size //     UIScreen.main.bounds.size
        hudWidth = screenSize.width
        hudHeight = screenSize.height
        
        
        /* Create overlay SKScene for 3D scene */
        overlay = SKScene(size: screenSize)
        overlay.scaleMode = SKSceneScaleMode.resizeFill
        overlay.isPaused = false
        theView.overlaySKScene = overlay
        initializeRows()
    }
    
    /// initialize rows: re-initializes the text-array with optional font size
    /// - Parameter fontSize: font size
    func initializeRows(fontSize: Int = 16){
        hudFontSize = CGFloat(fontSize)
        overlay.removeAllChildren()
        numberOfRows = Int(floor((hudHeight - CGFloat(2 * HUDMARGIN)) / hudFontSize))
        for i in 0..<numberOfRows{
            let row = SKLabelNode(fontNamed: "Courier")
            row.text = ""
            row.fontSize = hudFontSize
            row.fontColor = SKColor.green
            row.position = CGPoint(x: HUDMARGIN, y: Int(hudHeight) - HUDMARGIN - i * Int(hudFontSize))
            row.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
            row.verticalAlignmentMode = SKLabelVerticalAlignmentMode.top
            row.lineBreakMode = NSLineBreakMode.byClipping
            row.name = "\(i)"
            overlay.addChild(row)
        }
        clear()
    }
    
    /// Clear: erase all text
    func clear(){
        for i in 0..<numberOfRows{
            print(text: "", atLine: i)
        }
        cursorLine = 0
    }
    
    /// Print: the core printing routine, prints (or appends) text at cursor line position
    /// and increments cursorLine thereafter
    /// - Parameter text: the text string
    /// - Parameter atLine: cursorLine, default = -1 = current cursorLine
    /// - Parameter append: switch between print and append
    func print(text txt:String, atLine line: Int = -1, append: Bool = false){
        var line = line
        if (line < 0){
            line = cursorLine
        }
        if (cursorLine >= numberOfRows){
            return
        }
        let row = overlay.childNode(withName: "\(line)") as! SKLabelNode
        var rtext = ""
        if (append){
            rtext = row.text!
        }
        row.text = rtext + txt
        cursorLine = line + 1
    }
}

