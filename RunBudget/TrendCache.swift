//
//  TrendCache.swift
//  RunBudget
//
//  Created by Daniel Sauble on 11/18/16.
//  Copyright © 2016 Daniel Sauble. All rights reserved.
//

import Foundation

class TrendCache {
    
    // Singleton
    static var shared: TrendCache = TrendCache()
    
    var lastWeek = 0.0
    
    init() {
        // Autoload the saved value
        load()
    }
    
    // MARK: Load/save files
    
    func load() {
        if let value = NSKeyedUnarchiver.unarchiveObject(withFile: UnitStore.ArchiveURL.path) as? Double {
            lastWeek = value
        }
    }
    
    func save() {
        let success = NSKeyedArchiver.archiveRootObject(lastWeek, toFile: UnitStore.ArchiveURL.path)
        
        if (!success) {
            fatalError("Could not persist trend to disk")
        }
    }
    
    // MARK: Archiving Paths
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("trend")
}
