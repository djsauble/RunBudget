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

class RunController: WKInterfaceController, HKWorkoutSessionDelegate {

    var workoutSession: HKWorkoutSession? = nil
    var healthStore: HKHealthStore? = nil
    var runBudget: Int? = nil
    var distance: Double = 0
    
    @IBOutlet var runBudgetLabel: WKInterfaceLabel!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        loadContext(context: context)
        
        // Update the interface
        updateInterface()
        
        // Start a run
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .running
        configuration.locationType = .outdoor
        
        do {
            let workoutSession = try HKWorkoutSession(configuration: configuration)
            
            workoutSession.delegate = self
            
            self.workoutSession = workoutSession
            
            WorkoutData.shared.authorizeHealthKit(handler: {
                healthStore in
                
                healthStore.start(workoutSession)
                self.healthStore = healthStore
            })
        }
        catch let error as NSError {
            // Perform proper error handling here
            fatalError("*** Unable to create the workout session: \(error.localizedDescription) ***")
        }
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
        if let healthStore = self.healthStore, let workoutSession = self.workoutSession {
            healthStore.end(workoutSession)
        }
        
        self.dismiss()
    }
    
    func loadContext(context: Any?) {
        if let runBudget = context as? Int {
            self.runBudget = runBudget
        }
    }
    
    func updateInterface() {
        if let runBudget = self.runBudget {
            if UnitStore.shared.unit == HKUnit.mile() {
                runBudgetLabel.setText("\(runBudget) miles")
            }
            else {
                runBudgetLabel.setText("\(runBudget) km")
            }
        }
    }
    
    // MARK: HKWorkoutSessionDelegate
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        
        if toState == .running {
            if fromState == .notStarted {
                startSampling()
            }
        }
        else if toState == .ended {
            if fromState == .running {
                // Save workout
            }
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        fatalError("*** Unable to start the workout session: \(error.localizedDescription) *** ")
    }
    
    func startSampling() {
        print("Start sampling...")
        if let workoutSession = self.workoutSession, let healthStore = self.healthStore {
            // Object predicate
            
            let datePredicate = HKQuery.predicateForSamples(withStart: workoutSession.startDate, end: nil, options: .strictStartDate)
            let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
            let queryPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, devicePredicate])
            
            let quantityType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)
            guard quantityType != nil else {
                fatalError("*** Could not create a quantity type")
            }
            
            // Handle updates
            
            let updateHandler: (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = {
                query, samples, deletedObjects, queryAnchor, error in

                if let samples = samples as? [HKQuantitySample] {

                    for sample in samples {
                        self.distance += sample.quantity.doubleValue(for: UnitStore.shared.unit)
                    }
                    
                    print("\(self.distance) miles")
                }
            }
            
            let query = HKAnchoredObjectQuery(type: quantityType!,
                                              predicate: queryPredicate,
                                              anchor: nil,
                                              limit: HKObjectQueryNoLimit,
                                              resultsHandler: updateHandler)
            
            query.updateHandler = updateHandler
            
            healthStore.execute(query)
        }
    }
}
