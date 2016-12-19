//
//  WeekControl.swift
//  RunBudget
//
//  Created by Daniel Sauble on 12/18/16.
//  Copyright © 2016 Daniel Sauble. All rights reserved.
//

import UIKit

class WeekControl: UIView {
    
    // MARK: Properties
    
    var soFar: Double = 0.0
    var total: Double = 0.0
    var soFarView: UIView? = nil
    var remainingView: UIView? = nil
    
    // MARK: Initialization
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        
        var progress = self.soFar
        var remaining = self.total - self.soFar
        let total = self.total
        
        if self.soFar > self.total {
            progress = self.total
            remaining = 0.0
        }
        
        // Calculate bar dimensions
        let spacing = 1
        var bar1Width = CGFloat(0.0)
        var bar2Width = CGFloat(0.0)
        let barHeight = CGFloat(Double(frame.size.height))
        
        if progress == self.total {
            bar1Width = frame.size.width
            bar2Width = 0.0
        }
        else {
            bar1Width = (frame.size.width * CGFloat(progress / total)) - CGFloat(spacing)
            bar2Width = (frame.size.width * CGFloat(remaining / total))
        }
        
        // Layout the bars
        if let bar = self.soFarView {
            let barFrame = CGRect(x: CGFloat(0.0), y: CGFloat(0.0), width: bar1Width, height: barHeight)
            bar.frame = barFrame
        }
        if let bar = self.remainingView {
            if progress < self.total {
                let barFrame = CGRect(x: CGFloat(bar1Width) + CGFloat(spacing), y: CGFloat(0.0), width: bar2Width, height: barHeight)
                bar.frame = barFrame
            }
        }
    }

    func render() {
        
        var progress = self.soFar
        var remaining = self.total - self.soFar
        let total = self.total
        
        if self.soFar > self.total {
            progress = self.total
            remaining = 0.0
        }
        
        // Remove the existing bars
        if let bar = self.soFarView {
            bar.removeFromSuperview()
        }
        if let bar = self.remainingView {
            bar.removeFromSuperview()
        }
        
        // Calculate bar dimensions
        let spacing = 1
        var bar1Width = CGFloat(0.0)
        var bar2Width = CGFloat(0.0)
        let barHeight = CGFloat(Double(frame.size.height))

        if progress == self.total {
            bar1Width = frame.size.width
            bar2Width = 0.0
        }
        else {
            bar1Width = (frame.size.width * CGFloat(progress / total)) - CGFloat(spacing)
            bar2Width = (frame.size.width * CGFloat(remaining / total))
        }

        // Add the new bars
        let soFarView: UIView? = UIView(frame: CGRect(x: 0, y: 0, width: bar1Width, height: barHeight))
        if let bar = soFarView {
            bar.backgroundColor = UIColor.blue
            self.soFarView = bar
            self.addSubview(bar)
        }
        
        let remainingView: UIView? = UIView(frame: CGRect(x: 0, y: 0, width: bar2Width, height: barHeight))
        if let bar = remainingView {
            bar.backgroundColor = UIColor.gray
            self.remainingView = bar
            self.addSubview(bar)
        }
    
        // Perform layout
        self.setNeedsLayout()
    }
}
