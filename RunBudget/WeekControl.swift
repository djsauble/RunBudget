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
    var soFarView: UIView? = nil
    var remainingView: UIView? = nil
    
    // MARK: Initialization
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        
        let spacing = CGFloat(1)
        let total = self.frame.size.width - spacing
        
        var progress = self.soFar
        if self.soFar > 1 {
            progress = 1
        }
        
        // Calculate bar dimensions
        let bar1Width = total * CGFloat(progress)
        let bar2Width = total * CGFloat(1.0 - progress)
        let barHeight = CGFloat(Double(frame.size.height))
        
        // Layout the bars
        if let bar = self.soFarView {
            let barFrame = CGRect(x: CGFloat(0.0), y: 0.0, width: bar1Width, height: barHeight)
            bar.frame = barFrame
        }
        if let bar = self.remainingView {
            let barFrame = CGRect(x: bar1Width + spacing, y: 0.0, width: bar2Width, height: barHeight)
            bar.frame = barFrame
        }
    }

    func render() {
        
        let spacing = CGFloat(1)
        let total = self.frame.size.width - spacing
        
        var progress = self.soFar
        if self.soFar > 1 {
            progress = 1
        }
        
        // Calculate bar dimensions
        let bar1Width = total * CGFloat(progress)
        let bar2Width = total * CGFloat(1.0 - progress)
        let barHeight = CGFloat(Double(frame.size.height))

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
