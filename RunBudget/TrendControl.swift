//
//  TrendControl.swift
//  ForrestCruiseApp
//
//  Created by Daniel Sauble on 12/13/16.
//  Copyright © 2016 Daniel Sauble. All rights reserved.
//

import UIKit

class TrendControl: UIView {
    
    // MARK: Properties
    
    let maxWeeks = 26
    
    var workoutTrend = [Double]() {
        didSet {
            // Pad with zeroes
            while workoutTrend.count < maxWeeks {
                workoutTrend.insert(0, at: 0)
            }
            // Remove extra weeks
            while workoutTrend.count > maxWeeks {
                workoutTrend.remove(at: 0)
            }
            render()
        }
    }
    var workoutViews = [UIView?]()
    
    // MARK: Initialization
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        
        guard self.workoutTrend.count > 0 else {
            return
        }
        
        let spacing = 1
        let barWidth = (frame.size.width / CGFloat(self.workoutTrend.count)) - CGFloat(spacing)
        
        // Find the max bar height
        if let max = self.workoutTrend.max() {
            
            // Add trend bars
            for (index, bar) in workoutViews.enumerated() {
                if bar == nil {
                    continue
                }
                let barHeight = CGFloat(Double(frame.size.height) * self.workoutTrend[index] / max)
                let x = CGFloat(index) * (barWidth + CGFloat(spacing))
                let y = frame.size.height - barHeight
                let barFrame = CGRect(x: x, y: y, width: barWidth, height: barHeight)
                bar!.frame = barFrame
            }
        }
    }
    
    func render() {
        
        // Remove the existing workout bars
        workoutViews.forEach({
            (view: UIView?) in
            view?.removeFromSuperview()
        })
        workoutViews = []
        
        if let max = self.workoutTrend.max() {
            
            guard max > 0 else {
                return
            }
            
            // Add the new trend bars
            for i in 0..<self.workoutTrend.count {
                let view: UIView? = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 100 * self.workoutTrend[i] / max))
                
                if i < self.workoutTrend.count - 1 {
                    view!.backgroundColor = UIColor.gray
                }
                else {
                    view!.backgroundColor = UIColor.blue
                }
                
                self.workoutViews += [view]
                self.addSubview(view!)
            }
        }
        
        // Perform layout
        self.setNeedsLayout()
    }
}
