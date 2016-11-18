//
//  Session.swift
//  RunBudget
//
//  Created by Daniel Sauble on 11/18/16.
//  Copyright © 2016 Daniel Sauble. All rights reserved.
//

import Foundation
import WatchConnectivity
import HealthKit

class Session: NSObject, WCSessionDelegate {
    
    // Singleton
    static var shared: Session = Session()
    
    var session: WCSession? = nil

    // Callbacks
    var refreshComplications: (() -> Void)? = nil
    
    override init() {
        super.init()
        
        // Establish a session with the phone
        if WCSession.isSupported() {
            self.session = WCSession.default()
            self.session!.delegate = self
            self.session!.activate()
        }
    }
    
    // MARK: WatchConnectivity
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        var refresh = false

        // Check to see if the context has changed
        if let unit = applicationContext["unit"] as? String {
            if unit == "mi" && UnitStore.shared.unit == HKUnit.meter() {
                UnitStore.shared.unit = HKUnit.mile()
                UnitStore.shared.save()
                
                refresh = true
            }
            else if unit == "km" && UnitStore.shared.unit == HKUnit.mile() {
                UnitStore.shared.unit = HKUnit.meter()
                UnitStore.shared.save()
                
                refresh = true
            }
        }
        if let lastWeek = applicationContext["lastWeek"] as? Double {
            if lastWeek != TrendCache.shared.lastWeek {
                TrendCache.shared.lastWeek = lastWeek
                TrendCache.shared.save()
                
                refresh = true
            }
        }
        
        // If needed, refresh the UI
        if refresh {
            if let callback = self.refreshComplications {
                DispatchQueue.main.async() {
                    callback()
                }
            }
        }
    }
}
