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
        handler(Date())
    }
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(Date(timeIntervalSinceNow: (60 * 60 * 48)))
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        
        // Get the appropriate units to use
        let unit = UnitStore.shared.toString()
        
        WorkoutData.shared.trendingData(unit: UnitStore.shared.unit, handler: {
            (point: WorkoutData.Point) in
            
            // Create the correct type of complication
            if complication.family == .circularSmall {
                handler(self.getCircularSmallEntry(date: Date(), value: point.rightNow, unit: unit))
            }
            else if complication.family == .modularSmall {
                handler(self.getModularSmallEntry(date: Date(), value: point.rightNow, unit: unit))
            }
            else if complication.family == .modularLarge {
                handler(self.getModularLargeEntry(date: Date(), lastWeek: point.lastWeek, thisWeek: point.targetMileage, soFar: point.thisWeek, rightNow: point.rightNow, unit: unit))
            }
            else if complication.family == .utilitarianSmall || complication.family == .utilitarianSmallFlat {
                handler(self.getUtilitarianSmallEntry(date: Date(), value: point.rightNow, unit: unit))
            }
            else if complication.family == .utilitarianLarge {
                handler(self.getUtilitarianLargeEntry(date: Date(), thisWeek: point.targetMileage, soFar: point.thisWeek, rightNow: point.rightNow, unit: unit))
            }
            else {
                handler(nil)
            }
        })
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {

        // Get the appropriate units to use
        let unit = UnitStore.shared.toString()
        let hourInSeconds = 60.0 * 60.0
        var currentHour = date
        var entries = [CLKComplicationTimelineEntry]()
        
        WorkoutData.shared.futureData(unit: UnitStore.shared.unit, after: date, limit: limit, handler: {
            (points: [WorkoutData.Point]) in
            // Create the correct type of complication
            if complication.family == .circularSmall {
                for point in points {
                    currentHour.addTimeInterval(hourInSeconds)
                    entries.append(self.getCircularSmallEntry(date: currentHour, value: point.rightNow, unit: unit))
                }
                handler(entries)
            }
            else if complication.family == .modularSmall {
                for point in points {
                    currentHour.addTimeInterval(hourInSeconds)
                    entries.append(self.getModularSmallEntry(date: currentHour, value: point.rightNow, unit: unit))
                }
                handler(entries)
            }
            else if complication.family == .modularLarge {
                for point in points {
                    currentHour.addTimeInterval(hourInSeconds)
                    entries.append(self.getModularLargeEntry(date: currentHour, lastWeek: point.lastWeek, thisWeek: point.targetMileage, soFar: point.thisWeek, rightNow: point.rightNow, unit: unit))
                }
                handler(entries)
            }
            else if complication.family == .utilitarianSmall || complication.family == .utilitarianSmallFlat {
                for point in points {
                    currentHour.addTimeInterval(hourInSeconds)
                    entries.append(self.getUtilitarianSmallEntry(date: currentHour, value: point.rightNow, unit: unit))
                }
                handler(entries)
            }
            else if complication.family == .utilitarianLarge {
                for point in points {
                    currentHour.addTimeInterval(hourInSeconds)
                    entries.append(self.getUtilitarianLargeEntry(date: currentHour, thisWeek: point.targetMileage, soFar: point.thisWeek, rightNow: point.rightNow, unit: unit))
                }
                handler(entries)
            }
            else {
                handler(nil)
            }
        })
    }
    
    func getCircularSmallEntry(date: Date, value: Int, unit: String) -> CLKComplicationTimelineEntry {
        let template = CLKComplicationTemplateCircularSmallSimpleText()
        
        if unit == "mi" {
            template.textProvider = CLKSimpleTextProvider(text: "\(value)")
        }
        else {
            template.textProvider = CLKSimpleTextProvider(text: "\(value / 1000)")
        }
        
        return CLKComplicationTimelineEntry(date: date, complicationTemplate: template)
    }
    
    func getModularSmallEntry(date: Date, value: Int, unit: String) -> CLKComplicationTimelineEntry {
        let template = CLKComplicationTemplateModularSmallStackText()
        
        if unit == "mi" {
            template.line1TextProvider = CLKSimpleTextProvider(text: "\(value)")
        }
        else {
            template.line1TextProvider = CLKSimpleTextProvider(text: "\(value / 1000)")
        }
        template.line2TextProvider = CLKSimpleTextProvider(text: unit)
        
        return CLKComplicationTimelineEntry(date: date, complicationTemplate: template)
    }
    
    func getModularLargeEntry(date: Date, lastWeek: Double, thisWeek: Double, soFar: Double, rightNow: Int, unit: String) -> CLKComplicationTimelineEntry {
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
        
        return CLKComplicationTimelineEntry(date: date, complicationTemplate: template)
    }
    
    func getUtilitarianSmallEntry(date: Date, value: Int, unit: String) -> CLKComplicationTimelineEntry {
        let template = CLKComplicationTemplateUtilitarianSmallFlat()
        
        if unit == "mi" {
            template.textProvider = CLKSimpleTextProvider(text: "\(value) mi")
        }
        else {
            template.textProvider = CLKSimpleTextProvider(text: "\(value / 1000) km")
        }
        
        return CLKComplicationTimelineEntry(date: date, complicationTemplate: template)
    }
    
    func getUtilitarianLargeEntry(date: Date, thisWeek: Double, soFar: Double, rightNow: Int, unit: String) -> CLKComplicationTimelineEntry {
        let template = CLKComplicationTemplateUtilitarianLargeFlat()
        
        if unit == "mi" {
            template.textProvider = CLKSimpleTextProvider(text: "\(rightNow)/\(Int(soFar))/\(Int(thisWeek)) mi goal")
        }
        else {
            template.textProvider = CLKSimpleTextProvider(text: "\(rightNow / 1000)/\(Int(soFar / 1000))/\(Int(thisWeek / 1000)) km goal")
        }
        
        return CLKComplicationTimelineEntry(date: date, complicationTemplate: template)
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
