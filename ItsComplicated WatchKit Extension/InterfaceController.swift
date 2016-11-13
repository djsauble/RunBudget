//
//  InterfaceController.swift
//  ItsComplicated WatchKit Extension
//
//  Created by Daniel Sauble on 9/29/16.
//  Copyright © 2016 Daniel Sauble. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    @IBAction func testClick() {
        WorkoutData.shared.trendingData(handler: {
            (lastWeek: Double, thisWeek: Double, sinceMonday: TimeInterval, sinceLastWorkout: TimeInterval) in
            
            // Constants
            let weekInSeconds = Double(60 * 60 * 24 * 7)
            let percentageElapsed = sinceMonday / weekInSeconds
            let percentageRemaining = 1 - percentageElapsed
            
            // Calculate the number of miles you should run if you ran right now
            var miles = lastWeek - thisWeek - (percentageRemaining * lastWeek)
            if (miles < 0) {
                miles = 0
            }
            
            print(Int(miles))
        })
    }
}
