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
    var configuration: HKWorkoutConfiguration? = nil
    var runBudget: Int? = nil
    var unit: HKUnit? = nil
    var distance: Double = 0
    
    @IBOutlet var runBudgetLabel: WKInterfaceLabel!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        loadContext(context: context)
        
        // Set the units
        self.unit = UnitStore.shared.unit
        
        // Start a run
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .running
        configuration.locationType = .outdoor
        self.configuration = configuration
        
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
        if let healthStore = self.healthStore, let workoutSession = self.workoutSession {
            healthStore.end(workoutSession)
        }
        
        // Dismiss the controller
        self.dismiss()
    }
    
    func loadContext(context: Any?) {
        if let runBudget = context as? Int {
            self.runBudget = runBudget
        }
    }
    
    func updateInterface() {
        if let runBudget = self.runBudget {
            if self.unit == HKUnit.mile() {
                runBudgetLabel.setText("\(Double(Int((Double(runBudget) - self.distance) * 100.0)) / 100.0) mi left")
            }
            else {
                runBudgetLabel.setText("\(Double(Int((Double(runBudget) - self.distance) * 100.0)) / 100.0) km left")
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
                saveSamples()
            }
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        fatalError("*** Unable to start the workout session: \(error.localizedDescription) *** ")
    }
    
    func startSampling() {
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

                // Aggregate samples
                if let samples = samples as? [HKQuantitySample] {
                    for sample in samples {
                        self.distance += sample.quantity.doubleValue(for: self.unit ?? HKUnit.mile())
                    }
                }
                
                // Update the interface
                self.updateInterface()
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
    
    func saveSamples() {
        if let workoutSession = self.workoutSession, let healthStore = self.healthStore {
            let startDate = workoutSession.startDate ?? Date()
            let endDate = workoutSession.endDate ?? Date()
            let duration = endDate.timeIntervalSince(startDate)
            let distance = HKQuantity(unit: self.unit ?? HKUnit.mile(), doubleValue: self.distance)
            
            let workout = HKWorkout(activityType: self.configuration?.activityType ?? .running,
                                    start: startDate,
                                    end: endDate,
                                    duration: duration,
                                    totalEnergyBurned: nil,
                                    totalDistance: distance,
                                    device: HKDevice.local(),
                                    metadata: [HKMetadataKeyIndoorWorkout: (self.configuration?.locationType ?? .outdoor) == .indoor])
            
            guard healthStore.authorizationStatus(for: HKObjectType.workoutType()) == .sharingAuthorized else {
                print("*** the app does not have permission to save workout samples ***")
                return
            }
            
            healthStore.save(workout, withCompletion: { (success, error) -> Void in
                guard success else {
                    // Add proper error handling here...
                    print("*** Could not save the active energy burned samples: \(error?.localizedDescription) ***")
                    return
                }
            })
        }
    }
}
