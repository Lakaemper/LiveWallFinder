//
//  FeaturePointUpdateListener.swift
//  LiveWallFinder
//
//  Created by Rolf Lakaemper on 7/28/17.
//  Copyright © 2017 Rolf Lakaemper. All rights reserved.
//

import Foundation

protocol FeaturePointUpdateListener{
    func onFeaturePointsUpdated(featureCloud: FeatureCloud)
}
