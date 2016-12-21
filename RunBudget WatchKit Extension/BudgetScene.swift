//
//  BudgetScene.swift
//  RunBudget
//
//  Created by Daniel Sauble on 12/20/16.
//  Copyright © 2016 Daniel Sauble. All rights reserved.
//

import Foundation
import SpriteKit

class BudgetScene: SKScene {

    var percent: CGFloat = 100.0 {
        didSet {
            updateProgressBar()
        }
    }
    var soFarBar: SKSpriteNode!
    var progressBar: SKSpriteNode!

    override func sceneDidLoad() {
        self.backgroundColor = UIColor.white
        
        // Define the distance we’ve run so far
        self.soFarBar = SKSpriteNode(color: UIColor.lightGray, size: CGSize(width: 0, height: self.size.height))
        self.soFarBar.anchorPoint = CGPoint(x: 0, y: 0)
        
        // Define the progress bar
        self.progressBar = SKSpriteNode(color: UIColor.blue, size: CGSize(width: self.size.width, height: self.size.height))
        self.progressBar.anchorPoint = CGPoint(x: 0, y: 0)

        // Add bars to the scene
        if let scene = self.scene {
            scene.addChild(self.soFarBar)
            scene.addChild(self.progressBar)
        }
        
        // Update the scene
        self.updateProgressBar()
    }
    
    func updateProgressBar() {
        let totalWidth = self.size.width + 1

        if let bar = self.soFarBar {
            bar.size = CGSize(width: totalWidth * (1 - self.percent), height: self.size.height)
            bar.position = CGPoint(x: 0, y: 0)
        }
        if let bar = progressBar {
            bar.size = CGSize(width: totalWidth * self.percent, height: self.size.height)
            bar.position = CGPoint(x: totalWidth * (1 - self.percent) + 1, y: 0)
        }
    }
}
