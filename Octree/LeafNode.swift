//
//  Leaf.swift
//  LiveWallFinder
//
//  Created by Rolf Lakaemper on 8/16/17.
//  Copyright © 2017 Rolf Lakaemper. All rights reserved.
//

import Foundation

class LeafNode: Node{
    var ix: Int16
    var iy: Int16
    var iz: Int16
    
    init(_ ix: Int16, _ iy: Int16, _ iz: Int16){
        self.ix = ix
        self.iy = iy
        self.iz = iz
    }
}
