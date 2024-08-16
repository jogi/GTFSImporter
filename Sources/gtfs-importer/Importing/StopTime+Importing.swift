//
//  StopTime+Importing.swift
//  
//
//  Created by Vashishtha Jogi on 6/21/20.
//

import Foundation
import CSV
import GRDB
import GTFSModel
import OSLog

extension StopTime: ImporterImporting {
    static var fileName: String {
        return "stop_times.txt"
    }
    
    static func receiveImport(from reader: CSVReader, with db: Database) throws {
        do {
            let decoder = CSVRowDecoder()
            decoder.dateDecodingStrategy = .custom({ value in
                let sanitizedValue = value.sanitizedTimeString
                
                guard let date = DateFormatter.hhmmss.date(from: sanitizedValue) else {
                    throw ImporterError.invalidTime(time: "value: \(value) sanitizedValue: \(sanitizedValue)")
                }
                
                return date
            })
            var record = try decoder.decode(Self.self, from: reader)
            
            record.pickupType = record.pickupType ?? .regularlyScheduled
            record.dropoffType = record.dropoffType ?? .regularlyScheduled
            record.continuousPickup = record.continuousPickup ?? .notContinuous
            record.continuousDropoff = record.continuousDropoff ?? .notContinuous
            record.timepoint = record.timepoint ?? .exact
            record.isLastStop = false
            try record.insert(db)
        } catch {
            Logger.importer.error("Error importing \(Self.self) - \(error)\n\(reader.currentRow ?? [])")
        }
    }
}
