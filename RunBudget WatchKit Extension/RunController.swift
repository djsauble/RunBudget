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
    var workoutAborted: Bool = false
    var budgetHalfUsed: Bool = false
    var budgetAllUsed: Bool = false
    var paused: Bool = false
    
    // Samples
    var distanceSamples: [HKQuantitySample] = []
    var activeEnergyBurnedSamples: [HKQuantitySample] = []
    var heartRateSamples: [HKQuantitySample] = []
    
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
        self.workoutAborted = true

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
                startSamplingDistance()
                startSamplingActiveEnergyBurned()
                startSamplingHeartRate()
            }
            else if fromState == .paused {
                self.paused = false
                self.pauseButton.setTitle("Pause run")
                self.pauseButton.setBackgroundColor(UIColor.yellow)
            }
        }
        else if toState == .ended {
            if fromState == .running {
                saveWorkout()
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
    
    // Start a long-running query for any samples of a given type during the current workout session
    func startSampling(_ type: HKQuantityType, handler: @escaping ([HKSample]?) -> Void) {
        if let workoutSession = self.workoutSession, let healthStore = self.healthStore {
            
            // Object predicate
            
            let datePredicate = HKQuery.predicateForSamples(withStart: workoutSession.startDate, end: nil, options: .strictStartDate)
            let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
            let queryPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, devicePredicate])
            
            // Handle updates
            
            let updateHandler: (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = {
                query, samples, deletedObjects, queryAnchor, error in

                guard self.paused == false else {
                    // Do not accumulate distance while paused
                    return
                }
                
                handler(samples)
            }
            
            let query = HKAnchoredObjectQuery(type: type,
                                              predicate: queryPredicate,
                                              anchor: nil,
                                              limit: HKObjectQueryNoLimit,
                                              resultsHandler: updateHandler)
            
            query.updateHandler = updateHandler
            
            healthStore.execute(query)
        }
    }
    
    // Start a long-running query for walking/running distance
    func startSamplingDistance() {
        
        let quantityType: HKQuantityType! = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)
        guard quantityType != nil else {
            fatalError("*** Could not create a distance quantity type ***")
        }
        
        self.startSampling(quantityType, handler: {
            samples in
            
            // Aggregate samples
            if let samples = samples as? [HKQuantitySample] {
                
                // Add samples to the distance array
                self.distanceSamples.append(contentsOf: samples)
                
                // Sum the distances
                for sample in samples {
                    self.distance += sample.quantity.doubleValue(for: self.unit ?? HKUnit.mile())
                }
                
                // If we've used half or all of our run budget, play a haptic notification
                if let runBudget = self.runBudget {
                    if runBudget > 0 {
                        if Double(runBudget) <= self.distance * 2 && !self.budgetHalfUsed {
                            // Halfway point
                            WKInterfaceDevice.current().play(.notification)
                            self.budgetHalfUsed = true
                        }
                        else if Double(runBudget) <= self.distance && !self.budgetAllUsed {
                            // All done
                            WKInterfaceDevice.current().play(.notification)
                            self.budgetAllUsed = true
                        }
                    }
                }
            }
            
            // Update the interface
            self.updateInterface()
        })
    }
    
    // Start a long-running query for active energy burned
    func startSamplingActiveEnergyBurned() {
        
        let quantityType: HKQuantityType! = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)
        guard quantityType != nil else {
            fatalError("*** Could not create an active energy burned quantity type ***")
        }
        
        self.startSampling(quantityType, handler: {
            samples in
            
            // Aggregate samples
            if let samples = samples as? [HKQuantitySample] {
                self.activeEnergyBurnedSamples.append(contentsOf: samples)
            }
        })
    }
    
    // Start a long-running query for heart rate
    func startSamplingHeartRate() {
        
        let quantityType: HKQuantityType! = HKQuantityType.quantityType(forIdentifier: .heartRate)
        guard quantityType != nil else {
            fatalError("*** Could not create a heart rate quantity type")
        }
        
        self.startSampling(quantityType, handler: {
            samples in
            
            // Aggregate samples
            if let samples = samples as? [HKQuantitySample] {
                self.heartRateSamples.append(contentsOf: samples)
            }
        })
    }
    
    func saveWorkout() {
        
        guard self.workoutAborted else {
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
        if let healthStore = self.healthStore {
            
            // Add distance samples
            if !self.distanceSamples.isEmpty {
                healthStore.add(distanceSamples, to: workout, completion: {
                    success, error in
                    guard success else {
                        print("*** Could not save distance samples: \(error?.localizedDescription) ***")
                        return
                    }
                })
            }
            
            // Add active energy burned samples
            if !self.activeEnergyBurnedSamples.isEmpty {
                healthStore.add(activeEnergyBurnedSamples, to: workout, completion: {
                    success, error in
                    guard success else {
                        print("*** Could not save active energy burned samples: \(error?.localizedDescription) ***")
                        return
                    }
                })
            }
            
            // Add heart rate samples
            if !self.heartRateSamples.isEmpty {
                healthStore.add(heartRateSamples, to: workout, completion: {
                    success, error in
                    guard success else {
                        print("*** Could not save heart rate samples: \(error?.localizedDescription) ***")
                        return
                    }
                })
            }
        }
    }
}
