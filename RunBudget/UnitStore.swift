//
//  UnitStore.swift
//  RunBudget
//
//  Created by Daniel Sauble on 11/15/16.
//  Copyright © 2016 Daniel Sauble. All rights reserved.
//

import Foundation
import HealthKit

class UnitStore {
    
    // Singleton
    static var shared: UnitStore = UnitStore()
    
    var unit = HKUnit.mile() // Default unit is miles
    
    init() {
        // Autoload the saved value
        load()
    }
    
    func toString() -> String {
        if self.unit == HKUnit.mile() {
            return "mi"
        }
        else {
            return "km"
        }
    }
    
    // MARK: Load/save files
    
    func load() {
        if let value = NSKeyedUnarchiver.unarchiveObject(withFile: UnitStore.ArchiveURL.path) as? String {
            if value == "mi" {
                self.unit = HKUnit.mile()
            }
            else {
                self.unit = HKUnit.meter()
            }
        }
    }
    
    func save() {
        
        let success = NSKeyedArchiver.archiveRootObject(self.toString(), toFile: UnitStore.ArchiveURL.path)
        
        if (!success) {
            fatalError("Could not persist unit to disk")
        }
    }
    
    // MARK: Archiving Paths
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("files")
}
