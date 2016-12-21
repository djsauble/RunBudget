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
    @IBOutlet weak var runBudgetControl: BudgetControl!
    
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
                    self.howFarLabel.text = "\(point.rightNow) miles now"
                    self.thisWeekLabel.text = "\(Int(point.thisWeek)) of \(Int(point.targetMileage)) miles this week"
                    self.lastWeekLabel.text = "\(Int(point.lastWeek)) miles last week"
                }
                else {
                    self.howFarLabel.text = "\(Int(point.rightNow / 1000)) km now"
                    self.thisWeekLabel.text = "\(Int(point.thisWeek / 1000)) of \(Int(point.targetMileage / 1000)) km this week"
                    self.lastWeekLabel.text = "\(Int(point.lastWeek / 1000)) km last week"
                }
                
                self.thisWeekControl.soFar = Double(Int(point.thisWeek))
                self.thisWeekControl.total = Double(Int(point.targetMileage))
                self.thisWeekControl.render()
                
                self.runBudgetControl.soFar = Double(Int(point.thisWeek))
                self.runBudgetControl.budget = Double(Int(point.rightNow))
                self.runBudgetControl.total = Double(Int(point.targetMileage))
                self.runBudgetControl.render()
            }
            else {
                if UnitStore.shared.unit == HKUnit.mile() {
                    self.howFarLabel.text = "— miles now"
                    self.thisWeekLabel.text = "— of — miles this wek"
                    self.lastWeekLabel.text = "— miles last week"
                }
                else {
                    self.howFarLabel.text = "— km now"
                    self.thisWeekLabel.text = "— of — km this week"
                    self.lastWeekLabel.text = "— km last week"
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

