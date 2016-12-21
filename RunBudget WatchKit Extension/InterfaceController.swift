//
//  InterfaceController.swift
//  RunBudget WatchKit Extension
//
//  Created by Daniel Sauble on 9/29/16.
//  Copyright © 2016 Daniel Sauble. All rights reserved.
//

import WatchKit
import Foundation

class InterfaceController: WKInterfaceController {
    
    var runBudget: Int? = nil

    @IBOutlet var howFarLabel: WKInterfaceLabel!
    @IBOutlet var thisWeekLabel: WKInterfaceLabel!
    @IBOutlet var lastWeekLabel: WKInterfaceLabel!
    @IBOutlet var runBudgetSprite: WKInterfaceSKScene!
    @IBOutlet var startWorkout: WKInterfaceButton!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        
        // Initialize the scene
        let scene = WeeklyProgressScene(size: CGSize(width: self.contentFrame.width, height: 12))
        runBudgetSprite.presentScene(scene)
        
        // Start listening for new workouts
        WorkoutData.shared.listenForTrendingData(handler: self.updateInterface)
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    override func contextForSegue(withIdentifier segueIdentifier: String) -> Any? {
        if segueIdentifier == "startRun" {
            if let runBudget = runBudget {
                return runBudget
            }
        }
        
        return nil
    }
    
    func updateInterface() {
        let unit = UnitStore.shared.toString()
        
        WorkoutData.shared.trendingData(unit: UnitStore.shared.unit, handler: {
            (point: WorkoutData.Point?) in
            
            if let point = point {
                
                // Update labels
                if unit == "mi" {
                    self.howFarLabel.setText("\(point.rightNow) mi now")
                    self.thisWeekLabel.setText("\(Int(point.targetMileage)) mi this week")
                    self.lastWeekLabel.setText("\(Int(point.lastWeek)) mi last week")
                    self.runBudget = point.rightNow
                }
                else {
                    self.howFarLabel.setText("\(point.rightNow / 1000) km now")
                    self.thisWeekLabel.setText("\(Int(point.targetMileage / 1000)) km this week")
                    self.lastWeekLabel.setText("\(Int(point.lastWeek / 1000)) km last week")
                    self.runBudget = Int(point.rightNow / 1000)
                }
                
                // Update progress bar
                if let scene = self.runBudgetSprite.scene as? WeeklyProgressScene {
                    scene.soFarPercent = CGFloat(point.thisWeek / point.targetMileage)
                    scene.budgetPercent = CGFloat(Double(point.rightNow) / point.targetMileage)

                    // Normalize percentages
                    if scene.soFarPercent > 1 {
                        scene.soFarPercent = 1
                        scene.budgetPercent = 0
                    }
                    else if scene.soFarPercent + scene.budgetPercent > 1 {
                        scene.budgetPercent = 1 - scene.soFarPercent
                    }
                    
                    // Update the sprite
                    scene.updateProgressBar()
                }
            }
            else {
                if unit == "mi" {
                    self.howFarLabel.setText("— miles")
                    self.thisWeekLabel.setText("— of — miles")
                    self.lastWeekLabel.setText("— miles")
                }
                else {
                    self.howFarLabel.setText("— km")
                    self.thisWeekLabel.setText("— of — km")
                    self.lastWeekLabel.setText("— km")
                }
            }
            
            // Refresh the complications
            /*let server = CLKComplicationServer.sharedInstance()
            if let activeComplications = server.activeComplications {
                for complication in activeComplications {
                    server.reloadTimeline(for: complication)
                }
            }*/
        })
    }
}
