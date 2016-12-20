//
//  RunController.swift
//  RunBudget
//
//  Created by Daniel Sauble on 12/19/16.
//  Copyright © 2016 Daniel Sauble. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit

class RunController: WKInterfaceController {

    var distance: Int? = nil
    
    @IBOutlet var runBudgetLabel: WKInterfaceLabel!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        loadContext(context: context)
        
        // Update the interface
        updateInterface()
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    @IBAction func finishRun() {
        self.dismiss()
    }
    
    func loadContext(context: Any?) {
        if let distance = context as? Int {
            self.distance = distance
        }
    }
    
    func updateInterface() {
        if let distance = self.distance {
            if UnitStore.shared.unit == HKUnit.mile() {
                runBudgetLabel.setText("\(distance) miles")
            }
            else {
                runBudgetLabel.setText("\(distance) km")
            }
        }
    }
}
