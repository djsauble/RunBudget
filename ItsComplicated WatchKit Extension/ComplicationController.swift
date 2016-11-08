//
//  ComplicationController.swift
//  ItsComplicated WatchKit Extension
//
//  Created by Daniel Sauble on 9/29/16.
//  Copyright © 2016 Daniel Sauble. All rights reserved.
//

import ClockKit
import HealthKit

class ComplicationController: NSObject, CLKComplicationDataSource {
    
    // MARK: - Timeline Configuration
    
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        handler([.forward])
    }
    
    func getTimelineStartDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(NSDate() as Date)
    }
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(NSDate(timeIntervalSinceNow: (60 * 60 * 24)) as Date)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        // Call the handler with the current timeline entry
        if complication.family == .circularSmall {
            getHoursSinceLastWorkout(handler: {
                (hours: Int) in
                
                let template = CLKComplicationTemplateCircularSmallSimpleText()
                
                template.textProvider = CLKSimpleTextProvider(text: "Question", shortText: String(hours))
                
                let entry = CLKComplicationTimelineEntry(date: NSDate() as Date, complicationTemplate: template)
                
                handler(entry)
            })
        }
        else {
            handler(nil)
        }
    }
    
    func getTimelineEntries(for complication: CLKComplication, before date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries prior to the given date
        handler(nil)
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries after to the given date
        handler(nil)
    }
    
    // MARK: - Placeholder Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
        if complication.family == .circularSmall {
            let template = CLKComplicationTemplateCircularSmallSimpleText()
        
            template.textProvider = CLKSimpleTextProvider(text: "Exclamation", shortText: "!")
        
            handler(template)
        }
        else {
            handler(nil)
        }
    }
    
    // MARK: – Workout History
    
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
                done(healthStore)
            }
        })
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
