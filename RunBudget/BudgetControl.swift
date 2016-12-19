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
    var total: Double = 0.0
    var soFarView: UIView? = nil
    var budgetView: UIView? = nil
    var remainingView: UIView? = nil
    
    // MARK: Initialization
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        
        var progress = self.soFar
        var budget = self.budget
        var remaining = self.total - self.soFar - self.budget
        let total = self.total
        
        if self.soFar > total {
            progress = total
            remaining = 0.0
        }
        if self.budget > total - progress {
            budget = total - progress
        }
        
        // Calculate bar dimensions
        let spacing = CGFloat(1)
        var bar1Width = CGFloat(0)
        var bar2Width = CGFloat(0)
        var bar3Width = CGFloat(0)
        let barHeight = CGFloat(Double(frame.size.height))
        
        if progress == self.total {
            bar1Width = frame.size.width
            bar2Width = 0.0
            bar3Width = 0.0
        }
        else if budget == 0.0 {
            bar1Width = (frame.size.width * CGFloat(progress / total)) - spacing
            bar2Width = 0.0
            bar3Width = (frame.size.width * CGFloat(remaining / total))
        }
        else {
            bar1Width = (frame.size.width * CGFloat(progress / total)) - spacing
            bar2Width = (frame.size.width * CGFloat(budget / total)) - spacing
            bar3Width = (frame.size.width * CGFloat(remaining / total))
        }
        
        // Layout the bars
        if let bar = self.soFarView {
            let barFrame = CGRect(x: 0.0, y: 0.0, width: bar1Width, height: barHeight)
            bar.frame = barFrame
        }
        if let bar = self.budgetView {
            if budget > 0.0 {
                let barFrame = CGRect(x: bar1Width + spacing, y: 0.0, width: bar2Width, height: barHeight)
                bar.frame = barFrame
            }
        }
        if let bar = self.remainingView {
            if progress < self.total {
                let barFrame = CGRect(x: bar1Width + spacing + bar2Width + spacing, y: 0.0, width: bar3Width, height: barHeight)
                bar.frame = barFrame
            }
        }
    }
    
    func render() {
        
        var progress = self.soFar
        var budget = self.budget
        var remaining = self.total - self.soFar - self.budget
        let total = self.total
        
        if self.soFar > total {
            progress = total
            remaining = 0.0
        }
        if self.budget > total - progress {
            budget = total - progress
        }
        
        // Calculate bar dimensions
        let spacing = CGFloat(1)
        var bar1Width = CGFloat(0)
        var bar2Width = CGFloat(0)
        var bar3Width = CGFloat(0)
        let barHeight = CGFloat(Double(frame.size.height))
        
        if progress == self.total {
            bar1Width = frame.size.width
            bar2Width = 0.0
            bar3Width = 0.0
        }
        else if budget == 0.0 {
            bar1Width = (frame.size.width * CGFloat(progress / total)) - spacing
            bar2Width = 0.0
            bar3Width = (frame.size.width * CGFloat(remaining / total))
        }
        else {
            bar1Width = (frame.size.width * CGFloat(progress / total)) - spacing
            bar2Width = (frame.size.width * CGFloat(budget / total)) - spacing
            bar3Width = (frame.size.width * CGFloat(remaining / total))
        }
        
        // Add the new bars
        let soFarView: UIView? = UIView(frame: CGRect(x: 0, y: 0, width: bar1Width, height: barHeight))
        if let bar = soFarView {
            bar.backgroundColor = UIColor.lightGray
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
