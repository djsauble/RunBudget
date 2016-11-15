//
//  ComplicationController.swift
//  RunBudget WatchKit Extension
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
        handler(NSDate(timeIntervalSinceNow: (60 * 60 * 1)) as Date)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        
        WorkoutData.shared.trendingData(handler: {
            (lastWeek: Double, thisWeek: Double, soFar: Double, rightNow: Int, sinceLastWorkout: TimeInterval, sinceMonday: TimeInterval) in
            
            // Create the correct type of complication
            if complication.family == .circularSmall {
                let template = CLKComplicationTemplateCircularSmallSimpleText()
                
                template.textProvider = CLKSimpleTextProvider(text: "\(rightNow)")
                
                let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
                
                handler(entry)
            }
            else if complication.family == .modularSmall {
                let template = CLKComplicationTemplateModularSmallStackText()
                
                template.line1TextProvider = CLKSimpleTextProvider(text: "\(rightNow)")
                template.line2TextProvider = CLKSimpleTextProvider(text: "mi")
                
                let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
                
                handler(entry)
            }
            else if complication.family == .modularLarge {
                let template = CLKComplicationTemplateModularLargeTable()
                
                template.headerTextProvider = CLKSimpleTextProvider(text: "\(Int(lastWeek)) mi last week")
                
                template.row1Column1TextProvider = CLKSimpleTextProvider(text: "Week")
                template.row1Column2TextProvider = CLKSimpleTextProvider(text: "\(Int(soFar))/\(Int(thisWeek)) mi")
                
                template.row2Column1TextProvider = CLKSimpleTextProvider(text: "Now")
                template.row2Column2TextProvider = CLKSimpleTextProvider(text: "\(rightNow) mi")
                
                let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
                
                handler(entry)
            }
            else if complication.family == .utilitarianSmall {
                let template = CLKComplicationTemplateUtilitarianSmallFlat()
                
                template.textProvider = CLKSimpleTextProvider(text: "\(rightNow) mi")
                
                let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
                
                handler(entry)
            }
            else if complication.family == .utilitarianLarge {
                let template = CLKComplicationTemplateUtilitarianLargeFlat()
                
                template.textProvider = CLKSimpleTextProvider(text: "\(rightNow)/\(Int(soFar))/\(Int(thisWeek)) mi week")
                
                let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
                
                handler(entry)
            }
            else {
                handler(nil)
            }
        })
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

            template.textProvider = CLKSimpleTextProvider(text: "—")

            handler(template)
        }
        else if complication.family == .modularSmall {
            let template = CLKComplicationTemplateModularSmallStackText()
            
            template.line1TextProvider = CLKSimpleTextProvider(text: "—")
            template.line2TextProvider = CLKSimpleTextProvider(text: "miles")
            
            handler(template)
        }
        else if complication.family == .modularLarge {
            let template = CLKComplicationTemplateModularLargeTable()
            
            template.headerTextProvider = CLKSimpleTextProvider(text: "— mi last week")
            
            template.row1Column1TextProvider = CLKSimpleTextProvider(text: "Week")
            template.row1Column2TextProvider = CLKSimpleTextProvider(text: "—/— mi")
            
            template.row2Column1TextProvider = CLKSimpleTextProvider(text: "Now")
            template.row2Column2TextProvider = CLKSimpleTextProvider(text: "— mi")
            
            handler(template)
        }
        else if complication.family == .utilitarianSmall {
            let template = CLKComplicationTemplateUtilitarianSmallFlat()
            
            template.textProvider = CLKSimpleTextProvider(text: "— mi")
            
            handler(template)
        }
        else if complication.family == .utilitarianLarge {
            let template = CLKComplicationTemplateUtilitarianLargeFlat()
            
            template.textProvider = CLKSimpleTextProvider(text: "—/—/— mi week")
            
            handler(template)
        }
        else {
            handler(nil)
        }
    }
}
