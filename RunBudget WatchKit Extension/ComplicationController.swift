//
//  ComplicationController.swift
//  RunBudget WatchKit Extension
//
//  Created by Daniel Sauble on 9/29/16.
//  Copyright © 2016 Daniel Sauble. All rights reserved.
//

import ClockKit

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
        
        // Get the appropriate units to use
        let unit = UnitStore.shared.toString()
        
        WorkoutData.shared.trendingData(unit: UnitStore.shared.unit, handler: {
            (lastWeek: Double, thisWeek: Double, soFar: Double, rightNow: Int, sinceLastWorkout: TimeInterval, sinceMonday: TimeInterval) in
            
            // Create the correct type of complication
            if complication.family == .circularSmall {
                let template = CLKComplicationTemplateCircularSmallSimpleText()
                
                if unit == "mi" {
                    template.textProvider = CLKSimpleTextProvider(text: "\(rightNow)")
                }
                else {
                    template.textProvider = CLKSimpleTextProvider(text: "\(rightNow / 1000)")
                }
                
                let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
                
                handler(entry)
            }
            else if complication.family == .modularSmall {
                let template = CLKComplicationTemplateModularSmallStackText()
                
                if unit == "mi" {
                    template.line1TextProvider = CLKSimpleTextProvider(text: "\(rightNow)")
                }
                else {
                    template.line1TextProvider = CLKSimpleTextProvider(text: "\(rightNow / 1000)")
                }
                template.line2TextProvider = CLKSimpleTextProvider(text: unit)
                
                let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
                
                handler(entry)
            }
            else if complication.family == .modularLarge {
                let template = CLKComplicationTemplateModularLargeTable()
                
                if unit == "mi" {
                    template.headerTextProvider = CLKSimpleTextProvider(text: "\(Int(lastWeek)) mi last week")
                    
                    template.row1Column1TextProvider = CLKSimpleTextProvider(text: "Now")
                    template.row1Column2TextProvider = CLKSimpleTextProvider(text: "\(rightNow) mi")
                    
                    template.row2Column1TextProvider = CLKSimpleTextProvider(text: "Goal")
                    template.row2Column2TextProvider = CLKSimpleTextProvider(text: "\(Int(soFar)) of \(Int(thisWeek)) mi")
                }
                else {
                    template.headerTextProvider = CLKSimpleTextProvider(text: "\(Int(lastWeek / 1000)) km last week")
                    
                    template.row1Column1TextProvider = CLKSimpleTextProvider(text: "Now")
                    template.row1Column2TextProvider = CLKSimpleTextProvider(text: "\(rightNow / 1000) km")
                    
                    template.row2Column1TextProvider = CLKSimpleTextProvider(text: "Goal")
                    template.row2Column2TextProvider = CLKSimpleTextProvider(text: "\(Int(soFar / 1000)) of \(Int(thisWeek / 1000)) mi")
                }
                
                let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
                
                handler(entry)
            }
            else if complication.family == .utilitarianSmall {
                let template = CLKComplicationTemplateUtilitarianSmallFlat()
                
                if unit == "mi" {
                    template.textProvider = CLKSimpleTextProvider(text: "\(rightNow) mi")
                }
                else {
                    template.textProvider = CLKSimpleTextProvider(text: "\(rightNow / 1000) km")
                }
                
                let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
                
                handler(entry)
            }
            else if complication.family == .utilitarianLarge {
                let template = CLKComplicationTemplateUtilitarianLargeFlat()
                
                if unit == "mi" {
                    template.textProvider = CLKSimpleTextProvider(text: "\(rightNow)/\(Int(soFar))/\(Int(thisWeek)) mi goal")
                }
                else {
                    template.textProvider = CLKSimpleTextProvider(text: "\(rightNow / 1000)/\(Int(soFar / 1000))/\(Int(thisWeek / 1000)) km goal")
                }
                
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
        
        // Get the appropriate units to use
        let unit = UnitStore.shared.toString()
        
        // This method will be called once per supported complication, and the results will be cached
        if complication.family == .circularSmall {
            let template = CLKComplicationTemplateCircularSmallSimpleText()

            template.textProvider = CLKSimpleTextProvider(text: "—")

            handler(template)
        }
        else if complication.family == .modularSmall {
            let template = CLKComplicationTemplateModularSmallStackText()
            
            template.line1TextProvider = CLKSimpleTextProvider(text: "—")
            template.line2TextProvider = CLKSimpleTextProvider(text: unit)
            
            handler(template)
        }
        else if complication.family == .modularLarge {
            let template = CLKComplicationTemplateModularLargeTable()
            
            template.headerTextProvider = CLKSimpleTextProvider(text: "— \(unit) last week")
            
            template.row1Column1TextProvider = CLKSimpleTextProvider(text: "Now")
            template.row1Column2TextProvider = CLKSimpleTextProvider(text: "— \(unit)")
            
            template.row2Column1TextProvider = CLKSimpleTextProvider(text: "Goal")
            template.row2Column2TextProvider = CLKSimpleTextProvider(text: "— of — \(unit)")
            
            handler(template)
        }
        else if complication.family == .utilitarianSmall {
            let template = CLKComplicationTemplateUtilitarianSmallFlat()
            
            template.textProvider = CLKSimpleTextProvider(text: "— \(unit)")
            
            handler(template)
        }
        else if complication.family == .utilitarianLarge {
            let template = CLKComplicationTemplateUtilitarianLargeFlat()
            
            template.textProvider = CLKSimpleTextProvider(text: "—/—/— \(unit) week")
            
            handler(template)
        }
        else {
            handler(nil)
        }
    }
}
