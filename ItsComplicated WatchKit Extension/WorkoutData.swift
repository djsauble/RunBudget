//
//  WorkoutData.swift
//  ItsComplicated
//
//  Created by Daniel Sauble on 11/8/16.
//  Copyright © 2016 Daniel Sauble. All rights reserved.
//

import HealthKit

class WorkoutData {
    static var shared: WorkoutData = WorkoutData()
    var healthStore: HKHealthStore?
    
    // MARK: – Public interface
    
    // Fetch the number of hours that have elapsed since the last workout
    public func getHoursSinceLastWorkout(handler: @escaping (Int?) -> Void) -> Void {
        lastWorkout(handler: {
            (workout: HKWorkout?) in
            
            DispatchQueue.main.async() {
                if let workout = workout {
                    handler(Int(Date().timeIntervalSince(workout.startDate) / 60 / 60))
                }
                else {
                    handler(nil)
                }
            }
        })
    }

    // Get date of the last workout
    public func dateOfLastWorkout(handler: @escaping (Date?) -> Void) {
        lastWorkout(handler: {
            (workout: HKWorkout?) in
            
            DispatchQueue.main.async() {
                if let workout = workout {
                    handler(workout.startDate)
                }
                else {
                    handler(nil)
                }
            }
        })
    }
    
    // Listen for new workouts
    public func listenForWorkouts(handler: @escaping () -> Void) {
        authorizeHealthKit(handler: {
            (healthStore: HKHealthStore) in
            
            // Workouts
            let quantityType = HKObjectType.workoutType()
            
            // Only fetch running workouts
            let runningPredicate = HKQuery.predicateForWorkouts(with: .running)
            let startDatePredicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options: [.strictStartDate])
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [runningPredicate, startDatePredicate])
            
            // Listen for workouts
            let query = HKObserverQuery(sampleType: quantityType, predicate: predicate, updateHandler: {
                (query: HKObserverQuery, completionHandler: HKObserverQueryCompletionHandler, error: Error?) in

                if let error = error {
                    fatalError(error.localizedDescription)
                }
                else {
                    handler()
                    
                    // If you have subscribed for background updates you must call the completion handler here.
                    completionHandler()
                }
            })
            
            healthStore.execute(query)
        })
    }
    
    // MARK: – Private implementation
    
    // Get the last workout
    private func lastWorkout(handler: @escaping (HKWorkout?) -> Void) {
        authorizeHealthKit(handler: {
            (healthStore: HKHealthStore) in
            
            // Seven days ago
            let startDate = Date(timeIntervalSinceNow: -(60 * 60 * 24 * 7))
            
            // Workouts
            let quantityType = HKObjectType.workoutType()
            
            // Only fetch running workouts
            let runningPredicate = HKQuery.predicateForWorkouts(with: .running)
            let agePredicate = HKQuery.predicateForSamples(withStart: startDate, end: nil, options: [])
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [runningPredicate, agePredicate])
            
            // Get the most recent workout
            let query = HKSampleQuery(sampleType: quantityType, predicate: predicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: nil) {
                query, results, error in
                
                guard let samples = results as? [HKWorkout] else {
                    fatalError("An error occurred fetching the list of workouts")
                }
                
                if let last = samples.last {
                    handler(last)
                }
                else {
                    handler(nil)
                }
            }
            
            healthStore.execute(query)
        })
    }
    
    // Request authorization
    private func authorizeHealthKit(handler: @escaping (HKHealthStore) -> Void) {
        
        if let healthStore = self.healthStore {
            handler(healthStore)
        }
        else {
            // App requires HealthKit
            if !HKHealthStore.isHealthDataAvailable() {
                return
            }
            let healthStore = HKHealthStore()
        
            // Set the types you want to read from HK Store
            let healthKitTypesToRead = Set<HKObjectType>([
                HKObjectType.workoutType()
            ])
        
            // Request HealthKit authorization
            healthStore.requestAuthorization(toShare: nil, read: healthKitTypesToRead, completion: {
                (success: Bool, error: Error?) in
                if (success) {
                    self.healthStore = healthStore
                    handler(healthStore)
                }
            })
        }
    }
}
