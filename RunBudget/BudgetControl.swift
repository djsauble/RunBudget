//
//  BudgetControl.swift
//  RunBudget
//
//  Created by Daniel Sauble on 12/19/16.
//  Copyright © 2016 Daniel Sauble. All rights reserved.
//

import UIKit

class BudgetControl: UIView {
    
    // MARK: Properties
    
    var soFar: Double = 0.0
    var budget: Double = 0.0
    var soFarView: UIView? = nil
    var budgetView: UIView? = nil
    var remainingView: UIView? = nil
    
    // MARK: Initialization
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        
        var progress = self.soFar
        if progress > 1 {
            progress = 1
        }
        
        var budget = self.budget
        if budget + progress > 1 {
            budget = 1 - progress
        }
        
        // Calculate bar dimensions
        let spacing = CGFloat(1)
        let total = frame.size.width - 2 * spacing
        let bar1Width = CGFloat(progress) * total
        let bar2Width = CGFloat(budget) * total
        let bar3Width = total - bar1Width - bar2Width
        let barHeight = CGFloat(Double(frame.size.height))
        
        // Layout the bars
        if let bar = self.soFarView {
            let barFrame = CGRect(x: 0.0, y: 0.0, width: bar1Width, height: barHeight)
            bar.frame = barFrame
        }
        if let bar = self.budgetView {
            let barFrame = CGRect(x: bar1Width + spacing, y: 0.0, width: bar2Width, height: barHeight)
            bar.frame = barFrame
        }
        if let bar = self.remainingView {
            let barFrame = CGRect(x: bar1Width + spacing + bar2Width + spacing, y: 0.0, width: bar3Width, height: barHeight)
            bar.frame = barFrame
        }
    }
    
    func render() {
        
        var progress = self.soFar
        if progress > 1 {
            progress = 1
        }
        
        var budget = self.budget
        if budget + progress > 1 {
            budget = 1 - progress
        }
        
        // Calculate bar dimensions
        let spacing = CGFloat(1)
        let total = frame.size.width - 2 * spacing
        let bar1Width = CGFloat(progress) * total
        let bar2Width = CGFloat(budget) * total
        let bar3Width = total - bar1Width - bar2Width
        let barHeight = CGFloat(Double(frame.size.height))

        // Add the new bars
        let soFarView: UIView? = UIView(frame: CGRect(x: 0, y: 0, width: bar1Width, height: barHeight))
        if let bar = soFarView {
            bar.backgroundColor = UIColor.green
            self.soFarView = bar
            self.addSubview(bar)
        }
    
        let budgetView: UIView? = UIView(frame: CGRect(x: 0, y: 0, width: bar2Width, height: barHeight))
        if let bar = budgetView {
            bar.backgroundColor = UIColor.blue
            self.budgetView = bar
            self.addSubview(bar)
        }
    
        let remainingView: UIView? = UIView(frame: CGRect(x: 0, y: 0, width: bar3Width, height: barHeight))
        if let bar = remainingView {
            bar.backgroundColor = UIColor.gray
            self.remainingView = bar
            self.addSubview(bar)
        }
    
        // Perform layout
        self.setNeedsLayout()
    }
}
