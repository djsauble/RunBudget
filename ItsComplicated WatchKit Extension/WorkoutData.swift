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
                    handler(Int(Date().timeIntervalSince(workout.endDate) / 60 / 60))
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
    
    // Get trending data from the last two weeks
    //
    // * Miles last week
    // * Miles this week
    // * Time since last workout
    // * Time since Monday
    public func trendingData(handler: @escaping (Double, Double, TimeInterval, TimeInterval) -> Void) {
        authorizeHealthKit(handler: {
            (healthStore: HKHealthStore) in
            
            let calendar = Calendar.current
            
            // Get the Monday from this week
            var components = calendar.dateComponents([.year, .month, .day, .weekday], from: Date())
            if let day = components.day {
                if let offset = components.weekday {
                    components.day = day - ((offset - 1) + 6) % 7
                }
            }
            let thisMonday = calendar.date(from: components)
            
            // Get the Monday in the previous week
            if let day = components.day {
                components.day = day - 7
            }
            let lastMonday = calendar.date(from: components)
            
            // Compute sample query parameters
            let quantityType = HKObjectType.workoutType()
            let datePredicate = HKQuery.predicateForSamples(withStart: lastMonday, end: nil, options: [])
            let runningPredicate = HKQuery.predicateForWorkouts(with: .running)
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, runningPredicate])
            
            // Construct the query
            let query = HKSampleQuery(sampleType: quantityType, predicate: predicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: [], resultsHandler: {
                (query, samples, error) in
                
                var lastWeek = 0.0
                var thisWeek = 0.0
                var sinceMonday = 0.0
                var sinceLastWorkout = 0.0
                if let thisMonday = thisMonday {
                    
                    // Get the time elapsed since this Monday
                    sinceMonday = Date().timeIntervalSince(thisMonday)
                    
                    if let samples = samples as? [HKWorkout] {
                        
                        // Get the time elapsed since the last workout
                        if let lastWorkout = samples.last {
                            sinceLastWorkout = Date().timeIntervalSince(lastWorkout.endDate)
                        }
                        
                        // Sum the number of miles in each week
                        for sample in samples {
                            if let distance = sample.totalDistance?.doubleValue(for: HKUnit.mile()) {
                                if sample.startDate.compare(thisMonday) == .orderedAscending {
                                    lastWeek += distance
                                }
                                else {
                                    thisWeek += distance
                                }
                            }
                        }
                    }
                }
                
                handler(lastWeek, thisWeek, sinceLastWorkout, sinceMonday)
            })
            
            // Execute the query
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
