//
//  WeeklyProgressScene.swift
//  RunBudget
//
//  Created by Daniel Sauble on 12/20/16.
//  Copyright © 2016 Daniel Sauble. All rights reserved.
//

import Foundation
import SpriteKit

class WeeklyProgressScene: SKScene {
    
    var soFarPercent: CGFloat = 0.0
    var budgetPercent: CGFloat = 0.0

    var soFarBar: SKSpriteNode!
    var budgetBar: SKSpriteNode!
    var remainingBar: SKSpriteNode!
    
    override func sceneDidLoad() {
        self.backgroundColor = UIColor.white
        
        // Define the distance we've run so far this week
        self.soFarBar = SKSpriteNode(color: UIColor.blue, size: CGSize(width: 0, height: self.size.height))
        self.soFarBar.anchorPoint = CGPoint(x: 0, y: 0)
        
        // Define our current run budget
        self.budgetBar = SKSpriteNode(color: UIColor.green, size: CGSize(width: 0, height: self.size.height))
        self.budgetBar.anchorPoint = CGPoint(x: 0, y: 0)
        
        // Define the remaining mileage this week
        self.remainingBar = SKSpriteNode(color: UIColor.gray, size: CGSize(width: 0, height: self.size.height))
        self.remainingBar.anchorPoint = CGPoint(x: 0, y: 0)
        
        // Add bars to the scene
        if let scene = self.scene {
            scene.addChild(self.soFarBar)
            scene.addChild(self.budgetBar)
            scene.addChild(self.remainingBar)
        }
        
        // Update the progress bar
        self.updateProgressBar()
    }
    
    func updateProgressBar() {
        let totalWidth = self.size.width - 2
        
        if let bar = self.soFarBar {
            bar.size = CGSize(width: totalWidth * self.soFarPercent, height: self.size.height)
            bar.position = CGPoint(x: 0, y: 0)
        }
        if let bar = self.budgetBar {
            bar.size = CGSize(width: totalWidth * self.budgetPercent, height: self.size.height)
            bar.position = CGPoint(x: totalWidth * self.soFarPercent + 1, y: 0)
        }
        if let bar = self.remainingBar {
            bar.size = CGSize(width: totalWidth - (totalWidth * (self.soFarPercent + self.budgetPercent)), height: self.size.height)
            bar.position = CGPoint(x: (totalWidth * self.soFarPercent + 1) + (totalWidth * self.budgetPercent + 1), y: 0)
        }
    }
}
