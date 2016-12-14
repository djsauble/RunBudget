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
    
    var trend = [Double]() {
        didSet {
            // Pad with zeroes
            while trend.count < maxWeeks {
                trend.insert(0, at: 0)
            }
            // Remove extra weeks
            while trend.count > maxWeeks {
                trend.remove(at: 0)
            }
            render()
        }
    }
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
    var trendViews = [UIView?]()
    var workoutViews = [UIView?]()
    
    // MARK: Initialization
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        
        guard self.trend.count > 0 else {
            return
        }
        
        let spacing = 1
        let barWidth = (frame.size.width / CGFloat(self.trend.count)) - CGFloat(spacing)
        
        // Find the max bar height
        if let max = self.trend.max() {
            
            // Add trend bars
            for (index, bar) in trendViews.enumerated() {
                if bar == nil {
                    continue
                }
                let barHeight = CGFloat(Double(frame.size.height) * self.trend[index] / max)
                let x = CGFloat(index) * (barWidth + CGFloat(spacing))
                let y = frame.size.height - barHeight
                let barFrame = CGRect(x: x, y: y, width: barWidth, height: barHeight)
                bar!.frame = barFrame
            }
            
            // Add workout bars
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
        // Remove the existing trend bars
        trendViews.forEach({
            (view: UIView?) in
            view?.removeFromSuperview()
        })
        trendViews = []
        
        // Remove the existing workout bars
        workoutViews.forEach({
            (view: UIView?) in
            view?.removeFromSuperview()
        })
        workoutViews = []
        
        if let max = self.trend.max() {
            
            // Add the new trend bars
            for val in self.trend {
                let view: UIView? = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 100 * val / max))
                
                view!.backgroundColor = UIColor.red
                
                self.trendViews += [view]
                self.addSubview(view!)
            }
            
            // Add the new workout bars
            for val in self.workoutTrend {
                let view: UIView? = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 100 * val / max))
                
                view!.backgroundColor = UIColor.blue
                
                self.workoutViews += [view]
                self.addSubview(view!)
            }
        }
        
        // Perform layout
        self.setNeedsLayout()
    }
}
