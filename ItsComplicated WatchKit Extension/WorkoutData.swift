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
    
    // Fetch the number of hours that have elapsed since the last workout
    func getHoursSinceLastWorkout(handler: @escaping (Int) -> Void) -> Void {
        authorizeHealthKit(done: {
            (healthStore: HKHealthStore) in
            self.dateOfLastWorkout(healthStore: healthStore, done: {
                (date: Date) in
                DispatchQueue.main.async() {
                    handler(Int(Date().timeIntervalSince(date) / 60 / 60))
                }
            })
        })
    }
    
    // Request authorization
    func authorizeHealthKit(done: @escaping (HKHealthStore) -> Void) {
        
        if let healthStore = self.healthStore {
            done(healthStore)
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
                    done(healthStore)
                }
            })
        }
    }
    
    // Get date of the last workout
    func dateOfLastWorkout(healthStore: HKHealthStore, done: @escaping (Date) -> Void) {
        
        let quantityType = HKObjectType.workoutType()
        
        // Long-running query for daily data
        let query = HKSampleQuery(sampleType: quantityType, predicate: nil, limit: Int(HKObjectQueryNoLimit), sortDescriptors: nil) {
            query, results, error in
            
            guard let samples = results as? [HKWorkout] else {
                fatalError("An error occurred fetching the list of workouts")
            }
            
            done(samples.last!.startDate)
        }
        
        healthStore.execute(query)
    }
}
