//
//  Analysis1D.swift
//  PlaneFinder
//
//  Created by Rolf Lakaemper on 7/21/17.
//  Copyright © 2017 Rolf Lakaemper. All rights reserved.
//

import Foundation

class Analysis1D{
    
    /// entropy: compute base-2 entropy of vector
    /// - Parameter data: the data
    /// - returns: entropy (scalar)
    static func entropy(data  d: [Double])->Double{
        // normalize data
        var sum = 0.0
        for i in 0...d.count-1 {
            sum = sum + d[i]
        }
        var entr = 0.0
        for i in 0...d.count-1 {
            let di = d[i] / sum
            if (di > 0){
                entr = entr - di*log2(di)
            }
        }
        return(entr)
    }
    
    /// info: print vector info
    /// - Parameter data: the data
    static func info(data d:[Double]){
        print("Vector dimension: \(d.count)")
        for i in 0...d.count-1{
            print("\(i): \(d[i])")
        }
    }
    
    
    /// convolute: kernel convolution
    /// - Parameter data: the data
    /// - Parameter kernel: must have odd length.
    /// - returns: convoluted data array of same length
    static func convolute(data d: [Double], kernel k:[Double])->[Double]{
        var cp = [Double](repeating: 0.0, count: d.count)
        for i in 0...d.count-1{
            var sum = 0.0
            for j in 0...k.count-1{
                let indx = (i - j + k.count / 2) as Int
                if (indx >= 0 && indx < d.count){
                    sum = sum + d[indx] * k[j]
                }
            }
            cp[i] = sum
        }
        return(cp)
    }
    
    /// normalize local: scale length to 1 (in situ)
    /// - Parameter data: the data
    static func normalizeLocal(data d: inout [Double]){
        var sum = 0.0
        for dt in d{
            sum += dt
        }
        for i in 0...d.count-1{
            d[i] /= sum
        }
    }
    
    /// find peak at first / last position
    /// - Parameter data: the data
    /// - Parameter location: peak-location ["first" | "last"]
    /// - returns: peak as (index, value) tuple
    static func findPeak(data d: [Double], location loc:String)->(index: Int, value: Double){
        var start = 0
        var end = d.count-1
        var step = 1
        if (loc == "last"){
            start = d.count - 1
            end = 0
            step = -1
        }
        var peakValue = 0.0
        var peakIndex = -1
        for indx in stride(from: start, to: end, by: step){
            if (d[indx] < peakValue){
                break
            }
            peakIndex = indx
            peakValue = d[indx]
        }
        //
        // nothing found: set index to outer bounds
        if (peakValue == 0.0){
            if (loc == "last"){
                peakIndex = d.count - 1
            } else {
                peakIndex = 0
            }
        }
        
        return(peakIndex, peakValue)
    }
    
    
    /// threshhold (in situ)
    
    static func threshLocal(data d: inout [Double], thresh: Double){
        for i in 0...d.count-1{
            if (d[i] < thresh){
                d[i] = 0
            }
        }
    }
    
    
    
}
