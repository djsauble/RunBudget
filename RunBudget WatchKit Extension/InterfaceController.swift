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
            (point: WorkoutData.Point?) in
            
            if let point = point {
                if unit == "mi" {
                    self.howFarLabel.setText("\(point.rightNow) miles")
                    self.thisWeekLabel.setText("\(Int(point.thisWeek)) of \(Int(point.targetMileage)) miles")
                    self.lastWeekLabel.setText("\(Int(point.lastWeek)) miles")
                }
                else {
                    self.howFarLabel.setText("\(point.rightNow / 1000) km")
                    self.thisWeekLabel.setText("\(Int(point.thisWeek / 1000)) of \(Int(point.targetMileage / 1000)) km")
                    self.lastWeekLabel.setText("\(Int(point.lastWeek / 1000)) km")
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
        })
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
}
