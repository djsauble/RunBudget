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

    @IBOutlet var howFarLabel: WKInterfaceLabel!
    @IBOutlet var thisWeekLabel: WKInterfaceLabel!
    @IBOutlet var lastWeekLabel: WKInterfaceLabel!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        let unit = UnitStore.shared.toString()
        
        WorkoutData.shared.trendingData(unit: UnitStore.shared.unit, handler: {
            (lastWeek: Double, thisWeek: Double, soFar: Double, rightNow: Int, sinceLastWorkout: TimeInterval, sinceMonday: TimeInterval) in
            
            if unit == "mi" {
                self.howFarLabel.setText("\(rightNow) miles")
                self.thisWeekLabel.setText("\(Int(soFar)) of \(Int(thisWeek)) miles")
                self.lastWeekLabel.setText("\(Int(lastWeek)) miles")
            }
            else {
                self.howFarLabel.setText("\(rightNow / 1000) km")
                self.thisWeekLabel.setText("\(Int(soFar / 1000)) of \(Int(thisWeek / 1000)) km")
                self.lastWeekLabel.setText("\(Int(lastWeek / 1000)) km")
            }
        })
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
}
