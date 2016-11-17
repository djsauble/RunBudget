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

class ViewController: UIViewController, WCSessionDelegate {

    @IBOutlet weak var howFarLabel: UILabel!
    @IBOutlet weak var lastWeekLabel: UILabel!
    @IBOutlet weak var thisWeekLabel: UILabel!
    @IBOutlet weak var unitControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Load the last persisted unit
        loadUnits()
        
        // Refresh displayed data
        refreshData()
        
        // Establish a session with the watch
        if WCSession.isSupported() {
            let session = WCSession.default()
            session.delegate = self
            session.activate()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func unitsChanged(_ sender: Any) {
        if let button = sender as? UISegmentedControl {
            saveUnits(control: button)
            refreshData()
            
            // Send the new unit to the watch
            let session = WCSession.default()
            if session.activationState == .activated {
                do {
                    try session.updateApplicationContext(["unit": UnitStore.shared.toString()])
                }
                catch {
                    print("Could not send application context to the watch")
                }
            }
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
        WorkoutData.shared.trendingData(unit: UnitStore.shared.unit, handler: {
            (point: WorkoutData.Point) in
            
            if UnitStore.shared.unit == HKUnit.mile() {
                self.howFarLabel.text = "\(point.rightNow) miles"
                self.thisWeekLabel.text = "\(Int(point.thisWeek)) of \(Int(point.targetMileage)) miles"
                self.lastWeekLabel.text = "\(Int(point.lastWeek)) miles"
            }
            else {
                self.howFarLabel.text = "\(Int(point.rightNow / 1000)) km"
                self.thisWeekLabel.text = "\(Int(point.thisWeek / 1000)) of \(Int(point.targetMileage / 1000)) km"
                self.lastWeekLabel.text = "\(Int(point.lastWeek / 1000)) km"
            }
        })
    }
    
    // MARK: WatchConnectivity
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
    }
}

