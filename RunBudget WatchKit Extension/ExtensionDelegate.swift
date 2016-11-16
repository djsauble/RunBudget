//
//  ExtensionDelegate.swift
//  RunBudget WatchKit Extension
//
//  Created by Daniel Sauble on 9/29/16.
//  Copyright © 2016 Daniel Sauble. All rights reserved.
//

import WatchKit
import WatchConnectivity
import HealthKit

class ExtensionDelegate: NSObject, WKExtensionDelegate, WCSessionDelegate {
    
    override init() {
        super.init()
        
        // Refresh complications and schedule the next refresh
        scheduleComplicationRefresh()
        refreshComplications()
        
        // Establish a session with the phone
        if WCSession.isSupported() {
            let session = WCSession.default()
            session.delegate = self
            session.activate()
        }
    }

    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                self.scheduleComplicationRefresh()
                self.refreshComplications()
                backgroundTask.setTaskCompleted()
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompleted()
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompleted()
            default:
                // make sure to complete unhandled task types
                task.setTaskCompleted()
            }
        }
    }
    
    func refreshComplications() {
        print("Refreshing complications")
        let server = CLKComplicationServer.sharedInstance()
        if let activeComplications = server.activeComplications {
            for complication in activeComplications {
                server.reloadTimeline(for: complication)
            }
        }
    }
    
    func scheduleComplicationRefresh() {
        WorkoutData.shared.dateOfLastWorkout(handler: {
            (date: Date?) in
            
            if let date = date {
                
                let now = Date()
                
                let calendar = Calendar.current
                
                // What is the current offset in seconds from the top of the hour
                let nowOffset = (calendar.component(.minute, from: now) * 60) + (calendar.component(.second, from: now))
                
                // What was the offset of the last workout in seconds from the top of the hour
                let dateOffset = (calendar.component(.minute, from: date) * 60) + (calendar.component(.second, from: date))
                
                // When should the next update be?
                var nextRefresh: Date
                if nowOffset < dateOffset {
                    nextRefresh = Date(timeIntervalSinceNow: TimeInterval(dateOffset - nowOffset))
                }
                else {
                    nextRefresh = Date(timeIntervalSinceNow: TimeInterval((60 * 60) - (nowOffset - dateOffset)))
                }
                print("Next refresh on \(nextRefresh)")
                
                // Do the thing
                WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: nextRefresh, userInfo: nil, scheduledCompletion: {
                    (error: Error?) in
                    
                    if let error = error {
                        fatalError(error.localizedDescription)
                    }
                })
            }
        })
    }
    
    // MARK: WatchConnectivity
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async() {
            if let unit = applicationContext["unit"] as? String {
                if unit == "mi" {
                    UnitStore.shared.unit = HKUnit.mile()
                }
                else {
                    UnitStore.shared.unit = HKUnit.meter()
                }
                self.refreshComplications()
                UnitStore.shared.save()
            }
        }
    }
}
