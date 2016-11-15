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
        
        WorkoutData.shared.trendingData(handler: {
            (lastWeek: Double, thisWeek: Double, soFar: Double, rightNow: Int, sinceLastWorkout: TimeInterval, sinceMonday: TimeInterval) in
            
            self.howFarLabel.setText("\(rightNow) miles")
            self.thisWeekLabel.setText("\(Int(soFar))/\(Int(thisWeek)) miles")
            self.lastWeekLabel.setText("\(Int(lastWeek)) miles")
        })
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
}
