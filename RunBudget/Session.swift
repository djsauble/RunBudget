//
//  Session.swift
//  RunBudget
//
//  Created by Daniel Sauble on 11/18/16.
//  Copyright © 2016 Daniel Sauble. All rights reserved.
//

import Foundation

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
    
    var session: WCSession?
    
    override init() {
        super.init()
        
        // Init members
        if WCSession.isSupported() {
            self.session = WCSession.default()
            self.session!.delegate = self
            self.session!.activate()
        }
    }

    // Send updated context to the watch
    func sendUpdatedContext() {
        print("Sending updated context...")
        if let session = self.session {
            if session.activationState == .activated {
                do {
                    try session.updateApplicationContext([
                        "unit": UnitStore.shared.toString(),
                        "lastWeek": TrendCache.shared.lastWeek
                    ])
                }
                catch {
                    print("Failed to update application context")
                }
            }
            else {
                // Retry send
                print("Session is not active, retrying...")
            }
        }
    }
    
    // MARK: WatchConnectivity
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        }
        else if activationState == .activated {
            sendUpdatedContext()
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("Session became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("Session was deactivated")
    }
}
