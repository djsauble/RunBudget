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
            updateProgressBar(percent: self.percent)
        }
    }
    var progressBar: SKSpriteNode!

    override func sceneDidLoad() {
        print("sceneDidLoad()")
        
        self.progressBar = nil
        self.backgroundColor = UIColor.lightGray
        
        // Define the progress bar
        self.progressBar = SKSpriteNode(color: UIColor.blue, size: CGSize(width: self.size.width, height: self.size.height))
        self.progressBar.anchorPoint = CGPoint(x: 0, y: 0)
        self.updateProgressBar(percent: self.percent)

        if let scene = self.scene {
            scene.addChild(self.progressBar)
        }
    }
    
    func updateProgressBar(percent: CGFloat) {
        if let bar = progressBar {
            bar.size = CGSize(width: self.size.width * percent, height: self.size.height)
            bar.position = CGPoint(x: self.size.width - (self.size.width * self.percent), y: 0)
        }
    }
}
