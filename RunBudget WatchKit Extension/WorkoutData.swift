//
//  WorkoutData.swift
//  RunBudget
//
//  Created by Daniel Sauble on 11/8/16.
//  Copyright © 2016 Daniel Sauble. All rights reserved.
//

import HealthKit

class WorkoutData {
    
    // Constants
    let primePercentage = 2.0 / 7.0
    let throughFriday = Double(60 * 60 * 24 * 5)
    let weekInSeconds = Double(60 * 60 * 24 * 7)
    
    // Trend point
    struct Point {
        var lastWeek: Double
        var targetMileage: Double
        var thisWeek: Double
        var rightNow: Int
        var sinceLastWorkout: TimeInterval
        var sinceMonday: TimeInterval
    }
    
    // Singleton
    static var shared: WorkoutData = WorkoutData()
    
    var healthStore: HKHealthStore?
    
    // MARK: – Public interface
    
    // Get future data
    //
    // Returns:
    // * Array of distances you could run in each of the next hours
    public func futureData(unit: HKUnit, after: Date, limit: Int, handler: @escaping ([Point]?) -> Void) {
        trendingData(unit: unit, handler: {
            (point: Point?) in
            
            if let point = point {
            
                let calendar = Calendar.current
                
                // Get the Monday from this week
                var components = calendar.dateComponents([.year, .month, .day, .weekday], from: Date())
                if let day = components.day {
                    if let offset = components.weekday {
                        components.day = day - ((offset - 1) + 6) % 7
                    }
                }
                let thisMonday = calendar.date(from: components)
                
                // Initialize constants
                let targetMileageThisWeek = point.lastWeek * 1.1
                let targetMileageNextWeek = targetMileageThisWeek * 1.1
                var futureBudget = [Point]()
                let hourInSeconds = 60.0 * 60.0
                var offset = after.timeIntervalSince(thisMonday!)
                
                // Initialize temp variables for each element of our Point array
                var lastWeek = 0.0
                var targetMileage = 0.0
                var thisWeek = 0.0
                var rightNow = 0
                var sinceLastWorkout = 0.0
                var sinceMonday = 0.0
                
                // Calculate the miles you can run in the future
                for _ in 0..<limit {
                    
                    // What percentage of the weekly budget has been allocated?
                    var percentageElapsed = 0.0
                    if offset < self.throughFriday {
                        percentageElapsed = offset / self.weekInSeconds
                        
                        lastWeek = point.lastWeek
                        targetMileage = point.targetMileage
                        thisWeek = point.thisWeek
                        rightNow = Int((self.primePercentage * targetMileageThisWeek) + (percentageElapsed * targetMileageThisWeek) - point.thisWeek)
                        sinceLastWorkout = point.sinceLastWorkout
                        sinceMonday = offset
                    }
                    else if offset < self.weekInSeconds {
                        percentageElapsed = self.throughFriday / self.weekInSeconds
                        
                        lastWeek = point.lastWeek
                        targetMileage = point.targetMileage
                        thisWeek = point.thisWeek
                        rightNow = Int((self.primePercentage * targetMileageThisWeek) + (percentageElapsed * targetMileageThisWeek) - point.thisWeek)
                        sinceLastWorkout = point.sinceLastWorkout
                        sinceMonday = offset
                    }
                    else {
                        percentageElapsed = (offset - self.weekInSeconds) / self.weekInSeconds
                        
                        lastWeek = point.thisWeek
                        targetMileage = targetMileageNextWeek
                        thisWeek = 0.0
                        rightNow = Int((self.primePercentage * targetMileageNextWeek) + (percentageElapsed * targetMileageNextWeek))
                        sinceLastWorkout = point.sinceLastWorkout
                        sinceMonday = offset - self.weekInSeconds
                    }
                    
                    // Append the current point to the array
                    futureBudget.append(Point(lastWeek: lastWeek, targetMileage: targetMileage, thisWeek: thisWeek, rightNow: rightNow, sinceLastWorkout: sinceLastWorkout, sinceMonday: sinceMonday))
                    
                    // Fast forward to the next hour
                    offset += hourInSeconds
                }
                
                DispatchQueue.main.async() {
                    handler(futureBudget)
                }
            }
            else {
                DispatchQueue.main.async() {
                    handler(nil)
                }
            }
        })
    }
    
    // Get historic data from the last six months
    public func historicData(handler: @escaping ([Double]?) -> Void) {
        authorizeHealthKit(handler: {
            (healthStore: HKHealthStore) in
            
            let calendar = Calendar.current
            
            // Set the anchor date to Monday at 12:00 a.m.
            var components = calendar.dateComponents([.day, .month, .year, .weekday], from: Date())
            if let day = components.day {
                if let offset = components.weekday {
                    components.day = day - ((offset - 1) + 6) % 7
                }
            }

            guard let anchorDate = calendar.date(from: components) else {
                fatalError("*** Unable to create a valid date from the given components ***")
            }

            let quantityType = HKObjectType.workoutType()
            
            // Set the start date to 26 weeks before the anchor week
            let startDate = calendar.date(byAdding: .day, value: -7 * 26, to: anchorDate)
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: nil, options: [])

            // Set up the query
            let query = HKSampleQuery(sampleType: quantityType, predicate: predicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: nil) {
                query, results, error in
                
                guard let samples = results as? [HKWorkout] else {
                    fatalError("An error occurred fetching the list of workouts")
                }

                let weeks = self.aggregateIntoWeeks(samples: samples)
                
                // Call the callback on the main thread
                DispatchQueue.main.async() {
                    handler(weeks)
                }
            }
            
            // Run the query
            healthStore.execute(query)
        })
    }
    
    // Get trending data from the last two weeks
    //
    // * Distance last week
    // * Distance goal this week
    // * Distance traversed this week
    // * Distance I could run now
    // * Time since last workout
    // * Time since Monday
    public func trendingData(unit: HKUnit, handler: @escaping (Point?) -> Void) {
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
                (query: HKSampleQuery, samples: [HKSample]?, error: Error?) in
                
                if error == nil {
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
                                if let distance = sample.totalDistance?.doubleValue(for: unit) {
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
                    
                    // If the earliest sample date is more recent than last Monday, use the cached value instead
                    if healthStore.earliestPermittedSampleDate().compare(lastMonday!) == .orderedDescending {
                        // Use cached value
                        lastWeek = TrendCache.shared.lastWeek
                    }
                    else {
                        // Update the cache
                        TrendCache.shared.lastWeek = lastWeek
                        TrendCache.shared.save()
                    }
                    
                    // Calculate the percentage of the weekly budget that is remaining
                    let targetMileage = lastWeek * 1.1
                    var percentageElapsed = 0.0
                    if sinceMonday < self.throughFriday {
                        percentageElapsed = sinceMonday / self.weekInSeconds
                    }
                    else {
                        percentageElapsed = self.throughFriday / self.weekInSeconds
                    }
                    
                    // Calculate the number of miles you could run if you ran right now
                    let rightNow = Int((self.primePercentage * targetMileage) + (percentageElapsed * targetMileage) - thisWeek)
                    
                    DispatchQueue.main.async() {
                        handler(Point(lastWeek: lastWeek, targetMileage: targetMileage, thisWeek: thisWeek, rightNow: rightNow, sinceLastWorkout: sinceLastWorkout, sinceMonday: sinceMonday))
                    }
                }
                else {
                    // There was an error fetching data from HKHealthStore
                    DispatchQueue.main.async() {
                        handler(nil)
                    }
                }
            })
            
            // Execute the query
            healthStore.execute(query)
        })
    }
    
    // MARK: – Private implementation
    
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
    
    // Aggregate sample data by weeks
    private func aggregateIntoWeeks(samples: [HKWorkout]) -> [Double] {
        
        let calendar = Calendar.current
        
        // Get the Monday from this week
        var components = calendar.dateComponents([.year, .month, .day, .weekday], from: Date())
        if let day = components.day {
            if let offset = components.weekday {
                components.day = day - ((offset - 1) + 6) % 7
            }
        }
        let day0 = calendar.date(from: components)
        
        // Loop variables
        var current = day0
        var distanceSum = 0.0

        // Reverse the sample array so we process newest values first
        let input = samples.reversed()
        var output = [Double]()
        
        for sample in input {

            // If the next sample is older than the current week, append the current sum to the output array
            if current!.compare(sample.startDate) == .orderedDescending {
                output.append(distanceSum)
                distanceSum = sample.totalDistance?.doubleValue(for: HKUnit.mile()) ?? 0.0
                current = calendar.date(byAdding: .day, value: -7, to: current!)
                continue
            }

            // Add to the sum
            distanceSum += sample.totalDistance?.doubleValue(for: HKUnit.mile()) ?? 0.0
        }
        
        // Add the final sample to the output array
        output.append(distanceSum)
        
        return output.reversed()
    }
}
