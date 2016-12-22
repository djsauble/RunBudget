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
import SpriteKit
import UIKit

class RunController: WKInterfaceController, HKWorkoutSessionDelegate {

    var workoutSession: HKWorkoutSession? = nil
    var healthStore: HKHealthStore? = nil
    var configuration: HKWorkoutConfiguration? = nil
    var runBudget: Int? = nil
    var unit: HKUnit? = nil
    var distance: Double = 0
    var saveWorkout: Bool = true
    var paused: Bool = false
    
    @IBOutlet var runBudgetLabel: WKInterfaceLabel!
    @IBOutlet var runBudgetElapsed: WKInterfaceLabel!
    @IBOutlet var runBudgetSprite: WKInterfaceSKScene!
    @IBOutlet var pauseButton: WKInterfaceButton!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        self.setTitle("")
        
        // Initialize the scene
        let scene = BudgetScene(size: CGSize(width: self.contentFrame.width, height: 12))
        runBudgetSprite.presentScene(scene)

        // Load the run budget from the context passed to us
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

    @IBAction func toggleRun() {
        if let healthStore = self.healthStore, let workoutSession = self.workoutSession {
            if paused {
                healthStore.resumeWorkoutSession(workoutSession)
            }
            else {
                healthStore.pause(workoutSession)
            }
        }
    }

    @IBAction func finishRun() {
        
        // End the workout
        if let healthStore = self.healthStore, let workoutSession = self.workoutSession {
            healthStore.end(workoutSession)
        }
        
        // Dismiss the controller
        self.dismiss()
    }
    
    @IBAction func abortRun() {
        
        // Don't save the workout
        self.saveWorkout = false

        // End the workout
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
            
            // Remaining run budget is not allowed to be negative
            var remaining: Double = 0.0
            if Double(runBudget) - self.distance > 0 {
                remaining = Double(runBudget) - self.distance
            }

            // Update labels
            if self.unit == HKUnit.mile() {
                runBudgetLabel.setText("\(Double(Int(remaining * 100.0)) / 100.0) mi left")
                runBudgetElapsed.setText("\(Double(Int(ceil(self.distance * 100.0))) / 100.0) mi")
            }
            else {
                runBudgetLabel.setText("\(Double(Int(remaining * 100.0)) / 100.0) km left")
                runBudgetElapsed.setText("\(Double(Int(ceil(self.distance * 100.0))) / 100.0) km")
            }
            
            // Update progress bar
            if runBudget > 0 {
                if let scene = runBudgetSprite.scene as? BudgetScene {
                    scene.percent = CGFloat(1 - self.distance / Double(runBudget))
                    if scene.percent < 0 {
                        scene.percent = 0
                    }
                }
            }
        }
    }
    
    // MARK: HKWorkoutSessionDelegate
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        
        if toState == .running {
            if fromState == .notStarted {
                startSampling()
            }
            else if fromState == .paused {
                self.paused = false
                self.pauseButton.setTitle("Pause run")
                self.pauseButton.setBackgroundColor(UIColor.yellow)
            }
        }
        else if toState == .ended {
            if fromState == .running {
                saveSamples()
            }
        }
        else if toState == .paused {
            if fromState == .running {
                self.paused = true
                self.pauseButton.setTitle("Resume run")
                self.pauseButton.setBackgroundColor(UIColor.green)
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

                guard self.paused == false else {
                    // Do not accumulate distance while paused
                    return
                }

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
        
        guard self.saveWorkout else {
            // Don't save
            return;
        }
        
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
                if success {
                    self.addSamples(workout: workout)
                }
                else {
                    // Add proper error handling here...
                    print("*** Could not save the workout: \(error?.localizedDescription) ***")
                }
            })
        }
    }
    
    func addSamples(workout: HKWorkout) {
        if let workoutSession = self.workoutSession, let healthStore = self.healthStore {
            let startDate = workoutSession.startDate ?? Date()
            let endDate = workoutSession.endDate ?? Date()
            
            let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
            let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
            let queryPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, devicePredicate])
            
            // Query for active energy burned samples
            if let energyBurnedType = HKSampleType.quantityType(forIdentifier: .activeEnergyBurned) {
                
                // Handle results from energy burned query
                let energyBurnedQueryHandler: (HKSampleQuery, [HKSample]?, Error?) -> Void = {
                    query, samples, error in
                    
                    if let samples = samples {
                        healthStore.add(samples, to: workout, completion: {
                            success, error in
                            guard success else {
                                print("*** Could not save active energy burned samples: \(error?.localizedDescription) ***")
                                return
                            }
                        })
                    }
                }
                
                // Setup the query
                let query = HKSampleQuery(sampleType: energyBurnedType,
                                          predicate: queryPredicate,
                                          limit: HKObjectQueryNoLimit,
                                          sortDescriptors: nil,
                                          resultsHandler: energyBurnedQueryHandler)
                
                // Execute the query
                healthStore.execute(query)
            }
            
            // Query for heart rate
            if let heartRateType = HKSampleType.quantityType(forIdentifier: .heartRate) {
                
                // Handle results from heart rate query
                let heartRateQueryHandler: (HKSampleQuery, [HKSample]?, Error?) -> Void = {
                    query, samples, error in
                    
                    if let samples = samples {
                        healthStore.add(samples, to: workout, completion: {
                            success, error in
                            guard success else {
                                print("*** Could not save heart rate samples: \(error?.localizedDescription) ***")
                                return
                            }
                        })
                    }
                }
                
                // Setup the query
                let query = HKSampleQuery(sampleType: heartRateType,
                                          predicate: queryPredicate,
                                          limit: HKObjectQueryNoLimit,
                                          sortDescriptors: nil,
                                          resultsHandler: heartRateQueryHandler)
                
                // Execute the query
                healthStore.execute(query)
            }
        }
    }
}
