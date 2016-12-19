//
//  ViewController.swift
//  RunBudget
//
//  Created by Daniel Sauble on 9/29/16.
//  Copyright © 2016 Daniel Sauble. All rights reserved.
//

import UIKit
import HealthKit
import WatchConnectivity

class ViewController: UIViewController {

    @IBOutlet weak var howFarLabel: UILabel!
    @IBOutlet weak var lastWeekLabel: UILabel!
    @IBOutlet weak var thisWeekLabel: UILabel!
    @IBOutlet weak var unitControl: UISegmentedControl!
    @IBOutlet weak var trendControl: TrendControl!
    @IBOutlet weak var thisWeekControl: WeekControl!
    @IBOutlet weak var runBudgetControl: WeekControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        // Load the last persisted unit
        loadUnits()
        
        // Refresh displayed data
        refreshData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func unitsChanged(_ sender: Any) {
        if let button = sender as? UISegmentedControl {
            saveUnits(control: button)
            refreshData()
        }
    }
    
    func saveUnits(control: UISegmentedControl) {
        let unit = control.titleForSegment(at: control.selectedSegmentIndex)
        if unit == "Miles" {
            UnitStore.shared.unit = HKUnit.mile()
        }
        else {
            UnitStore.shared.unit = HKUnit.meter()
        }
        UnitStore.shared.save()
    }
    
    func loadUnits() {
        let unit = UnitStore.shared.unit
        
        if unit == HKUnit.mile() {
            unitControl.selectedSegmentIndex = 0
        }
        else {
            unitControl.selectedSegmentIndex = 1
        }
    }
    
    func refreshData() {
        
        // Update text
        WorkoutData.shared.trendingData(unit: UnitStore.shared.unit, handler: {
            (point: WorkoutData.Point?) in
            
            if let point = point {
                if UnitStore.shared.unit == HKUnit.mile() {
                    self.howFarLabel.text = "\(point.rightNow) miles"
                    self.thisWeekLabel.text = "\(Double(Int(point.thisWeek * 10.0)) / 10.0) of \(Double(Int(point.targetMileage * 10.0)) / 10.0) miles"
                    self.lastWeekLabel.text = "\(Int(point.lastWeek)) miles"
                }
                else {
                    self.howFarLabel.text = "\(Double(Int(point.rightNow / 1000 * 10)) / 10.0) km"
                    self.thisWeekLabel.text = "\(Double(Int(point.thisWeek / 1000 * 10)) / 10.0) of \(Double(Int(point.targetMileage / 1000 * 10)) / 10.0) km"
                    self.lastWeekLabel.text = "\(Double(Int(point.lastWeek / 1000 * 10)) / 10.0) km"
                }
                
                self.thisWeekControl.total = point.targetMileage
                self.thisWeekControl.soFar = point.thisWeek
                
                self.runBudgetControl.total = point.targetMileage
                self.runBudgetControl.soFar = point.thisWeek + Double(point.rightNow)
            }
            else {
                if UnitStore.shared.unit == HKUnit.mile() {
                    self.howFarLabel.text = "— miles"
                    self.thisWeekLabel.text = "— of — miles"
                    self.lastWeekLabel.text = "— miles"
                }
                else {
                    self.howFarLabel.text = "— km"
                    self.thisWeekLabel.text = "— of — km"
                    self.lastWeekLabel.text = "— km"
                }
            }
            
            // Send updated context to the watch
            Session.shared.sendUpdatedContext()
        })
        
        // Update graphs
        WorkoutData.shared.historicData(handler: {
            (weeks: [Double]?) in

            if let weeks = weeks {
                self.trendControl.workoutTrend = weeks
            }
        })
    }
}

